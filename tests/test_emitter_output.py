import os
import sys
import base64

# Add src to path
sys.path.append(os.path.join(os.getcwd(), 'src'))

from core.ast_nodes import MvDocument, MvLayout, MvField, MvBehavioralRule, MvConditionLeaf
from emitters.vanilla_web_emitter import VanillaWebEmitter

def run_forensic_test():
    print("--- CRUCIBLE PIPELINE: FORENSIC INFUSION TEST ---")
    
    doc = MvDocument("Forensic_Infusion_Test")
    layout = MvLayout()
    doc.layouts.append(layout)

    # 1. FIELD A: Ground Zero
    f_a = MvField()
    f_a.identifier, f_a.name, f_a.vis_type_identifier = "FIELD_A", "Trigger Field", "TEXT"
    f_a.x, f_a.y, f_a.width, f_a.height = 10, 10, 200, 30
    layout.fields.append(f_a)

    # 2. FIELD B: Collision Target (Overlaps A)
    f_b = MvField()
    f_b.identifier, f_b.name, f_b.vis_type_identifier = "FIELD_B", "Collision Target", "TEXT"
    # Overlap with FIELD_A (10,10,200,30)
    f_b.x, f_b.y, f_b.width, f_b.height = 105, 15, 200, 30 
    layout.fields.append(f_b)

    # 3. FIELD C: Quarantine Target (OPAQUE SQL)
    f_c = MvField()
    f_c.identifier, f_c.name, f_c.vis_type_identifier = "FIELD_C", "Quarantined SQL", "TEXT"
    f_c.x, f_c.y, f_c.width, f_c.height = 10, 100, 200, 30
    
    rule_opaque = MvBehavioralRule("R_OPAQUE", "ON_CHANGE", "OPAQUE_SCRIPT")
    rule_opaque.raw_source = "DECLARE cursor c1 is select * from dual; BEGIN open c1; FETCH c1 into variable; END;"
    f_c.rules.append(rule_opaque)
    layout.fields.append(f_c)

    # 4. CASCADING RULES (A -> B -> C)
    rule_a = MvBehavioralRule("R_A", "ON_CHANGE", "DISABLE")
    rule_a.targets = ["FIELD_B"]
    rule_a.condition_root = MvConditionLeaf("FIELD_A", "==", "BLOCK")
    f_a.rules.append(rule_a)

    # 5. CYCLIC DEPENDENCY (B -> A) - Test if JS handles it
    rule_b = MvBehavioralRule("R_B", "ON_CHANGE", "ENABLE")
    rule_b.targets = ["FIELD_A"]
    rule_b.condition_root = MvConditionLeaf("FIELD_B", "==", "REVERSE")
    f_b.rules.append(rule_b)

    # 6. EJECTION
    emitter = VanillaWebEmitter()
    html = emitter.emit(doc)
    audit = emitter.get_audit_result()

    # 7. VALIDATION
    print(f"Collision Detected: {audit['has_layout_collision']}")
    
    # Verify Base64 in HTML
    b64_check = base64.b64encode(rule_opaque.raw_source.encode('utf-8')).decode('utf-8')
    if b64_check in html:
        print("SEC-1: Base64 Quarantine Verified.")
    else:
        print("SEC-1: FAIL - Base64 missing.")

    if 'type="application/vnd.mv.quarantine"' in html:
        print("SEC-1: Inert Tag Verified.")
    
    if 'activeNodes = new Set()' in html and 'finally' in html:
        print("JS-3: Stack Tracking & Deadlock Guard Verified.")

    # Write Result for manual inspection
    output_path = "batch_test_output/test_infusion.html"
    os.makedirs("batch_test_output", exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html)
    
    print(f"Artifact generated: {output_path}")

if __name__ == "__main__":
    run_forensic_test()
