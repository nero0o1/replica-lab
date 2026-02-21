import os
import sys

# Add src to path
sys.path.append(os.path.join(os.getcwd(), 'src'))

from core.ast_nodes import MvDocument, MvLayout, MvField, MvBehavioralRule, MvProperty
from emitters.vanilla_web_emitter import VanillaWebEmitter

def test_infusion():
    doc = MvDocument("Infusion Test: Forensic Enforcements")
    layout = MvLayout()
    layout.width, layout.height = 800, 600
    doc.layouts.append(layout)

    # 1. Normal Field (A4 conversion check)
    f1 = MvField()
    f1.identifier, f1.name, f1.vis_type_identifier = "FIELD_NORMAL", "Patient Name", "TEXT"
    f1.x, f1.y, f1.width, f1.height = 100, 100, 300, 30
    f1.properties.append(MvProperty(9, "valor_inicial", "John Doe"))
    layout.fields.append(f1)

    # 2. Quarantined Field (Opaque Script)
    f2 = MvField()
    f2.identifier, f2.name, f2.vis_type_identifier = "FIELD_OPAQUE", "Clinical Notes", "TEXTAREA"
    f2.x, f2.y, f2.width, f2.height = 100, 150, 600, 100
    rule = MvBehavioralRule("R1", "ON_CHANGE", "OPAQUE_SCRIPT")
    rule.raw_source = "DECLARE v_temp NUMBER; BEGIN SELECT 1 INTO v_temp FROM dual; END;"
    f2.rules.append(rule)
    layout.fields.append(f2)

    # 3. Quarantined Field (Sensitive Macro)
    f3 = MvField()
    f3.identifier, f3.name, f3.vis_type_identifier = "FIELD_SENSITIVE", "Patient ID", "TEXT"
    f3.x, f3.y, f3.width, f3.height = 100, 270, 150, 30
    rule2 = MvBehavioralRule("R2", "ON_CHANGE", "ENABLE")
    rule2.raw_source = "SELECT 1 FROM dual WHERE cd_paciente = &<PAR_CD_PACIENTE>"
    f3.rules.append(rule2)
    layout.fields.append(f3)

    # 4. Shape (Pointer-Events check)
    f4 = MvField()
    f4.identifier, f4.name, f4.vis_type_identifier = "SHAPE_BG", "Decoration", "SHAPE"
    f4.x, f4.y, f4.width, f4.height = 50, 50, 700, 500
    f4.z_index = -1
    layout.fields.append(f4)

    # 5. Whitespace Integrity check
    f5 = MvField()
    f5.identifier, f5.name, f5.vis_type_identifier = "FIELD_WHITESPACE", "Empty Initial", "TEXT"
    f5.x, f5.y, f5.width, f5.height = 100, 320, 150, 30
    f5.properties.append(MvProperty(9, "valor_inicial", " "))
    layout.fields.append(f5)

    emitter = VanillaWebEmitter()
    html = emitter.emit(doc)

    output_path = os.path.join(os.getcwd(), 'batch_test_output', 'test_infusion.html')
    if not os.path.exists('batch_test_output'):
        os.makedirs('batch_test_output')
        
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html)
    
    print(f"Test Infusion generated successfully at: {output_path}")

if __name__ == "__main__":
    test_infusion()
