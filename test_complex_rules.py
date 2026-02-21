import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from core.ast_nodes import (
    MvDocument, MvLayout, MvField, 
    MvBehavioralRule, MvConditionGroup, MvConditionLeaf
)
from core.json_serializer import MvJsonSerializer
from core.json_parser import MvJsonParser
from core.xml_serializer import MvXmlSerializer

def test_composite_precedence():
    print("--- Testing Composite Precedence: (A AND B) OR C ---")
    
    doc = MvDocument("Precedence Test")
    layout = MvLayout()
    doc.layouts.append(layout)
    
    # Target Field
    target = MvField()
    target.identifier = "TARGET_FIELD"
    layout.fields.append(target)
    
    # Condition Subject Fields
    fields = {}
    for name in ["FieldA", "FieldB", "FieldC"]:
        f = MvField()
        f.identifier = name
        layout.fields.append(f)
        fields[name] = f
        
    # Rule: (A==1 AND B==2) OR (C==3)
    rule = MvBehavioralRule("R1", "ON_CHANGE", "ENABLE")
    rule.targets = ["TARGET_FIELD"]
    
    group_root = MvConditionGroup(connector="OR")
    
    group_left = MvConditionGroup(connector="AND")
    group_left.add_child(MvConditionLeaf("FieldA", "==", "1"))
    group_left.add_child(MvConditionLeaf("FieldB", "==", "2"))
    
    group_root.add_child(group_left)
    group_root.add_child(MvConditionLeaf("FieldC", "==", "3"))
    
    rule.condition_root = group_root
    fields["FieldA"].rules.append(rule)
    
    # Round-trip JSON
    print("[STEP 1] Serializing to JSON...")
    serializer = MvJsonSerializer()
    json_out = serializer.serialize(doc)
    
    print("[STEP 2] Parsing back to AST...")
    parser = MvJsonParser()
    doc_b = parser.parse(json_out)
    
    # Verification
    print("[STEP 3] Verifying AST B...")
    rule_b = doc_b.layouts[0].fields[1].rules[0] # FieldA's rule
    root_b = rule_b.condition_root
    
    assert isinstance(root_b, MvConditionGroup)
    assert root_b.connector == "OR"
    assert len(root_b.children) == 2
    
    left_b = root_b.children[0]
    assert isinstance(left_b, MvConditionGroup)
    assert left_b.connector == "AND"
    
    right_b = root_b.children[1]
    assert isinstance(right_b, MvConditionLeaf)
    assert right_b.subject_identifier == "FieldC"
    
    print("[RESULT] Composite Precedence: SUCCESS")

def test_circular_dependency():
    print("\n--- Testing Circular Dependency Detection: A -> B -> A ---")
    doc = MvDocument("Loop Test")
    layout = MvLayout()
    doc.layouts.append(layout)
    
    f1 = MvField()
    f1.identifier = "FieldA"
    
    f2 = MvField()
    f2.identifier = "FieldB"
    
    layout.fields = [f1, f2]
    
    # Rule 1: FieldA triggers FieldB
    r1 = MvBehavioralRule("R1", "ON_CHANGE", "ENABLE")
    r1.targets = ["FieldB"]
    r1.condition_root = MvConditionLeaf("FieldA", "==", "1")
    f1.rules.append(r1)
    
    # Rule 2: FieldB triggers FieldA (THE LOOP)
    r2 = MvBehavioralRule("R2", "ON_CHANGE", "ENABLE")
    r2.targets = ["FieldA"]
    r2.condition_root = MvConditionLeaf("FieldB", "==", "2")
    f2.rules.append(r2)
    
    print("[STEP 1] Running validate_dependency_graph...")
    is_valid = doc.validate_dependency_graph()
    
    if not is_valid:
        print("[RESULT] Circular Dependency Detection: SUCCESS (Cycle Blocked)")
    else:
        print("[RESULT] Circular Dependency Detection: FAILED (Cycle Missed)")
        sys.exit(1)

if __name__ == "__main__":
    try:
        test_composite_precedence()
        test_circular_dependency()
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
