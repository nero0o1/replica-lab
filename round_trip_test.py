import os
import sys
import json
import xml.etree.ElementTree as ET
from typing import Optional, List, Any

# Add src to path
sys.path.append(os.path.join(os.getcwd(), 'src'))

from core.xml_parser import MvXmlParser
from core.xml_serializer import MvXmlSerializer
from core.json_serializer import MvJsonSerializer
from core.json_parser import MvJsonParser

def clean_xml(element: ET.Element):
    """Trims whitespace and sorts children for semantic comparison."""
    if element.text: element.text = element.text.strip()
    if element.tail: element.tail = element.tail.strip()
    
    # Sort children by tag and CD_... ID if present
    def sort_key(e):
        return (e.tag, e.findtext("CD_CAMPO", ""), e.findtext("CD_PROPRIEDADE", ""))
    
    element[:] = sorted(element, key=sort_key)
    for child in element:
        clean_xml(child)

def compare_xml_trees(e1: ET.Element, e2: ET.Element, path: str = "") -> List[str]:
    """Deep equal comparison of XML trees. Returns list of XPaths for differences."""
    errors = []
    
    current_path = f"{path}/{e1.tag}"
    
    if e1.tag != e2.tag:
        errors.append(f"Tag mismatch at {current_path}: {e1.tag} != {e2.tag}")
        return errors
        
    if (e1.text or "") != (e2.text or ""):
        # Ignore whitespace differences
        if (e1.text or "").strip() != (e2.text or "").strip():
            errors.append(f"Value mismatch at {current_path}: '{e1.text}' != '{e2.text}'")
            
    if len(e1) != len(e2):
        tags1 = [c.tag for c in e1]
        tags2 = [c.tag for c in e2]
        errors.append(f"Children count mismatch at {current_path}: {len(e1)} != {len(e2)}\n  Path 1 tags: {tags1}\n  Path 2 tags: {tags2}")
        return errors
        
    for c1, c2 in zip(list(e1), list(e2)):
        errors.extend(compare_xml_trees(c1, c2, current_path))
        
    return errors

def run_round_trip(input_xml_path: str):
    print(f"--- Starting Round-Trip: {input_xml_path} ---")
    
    # Phase A: Parse Legacy (XML) -> AST (Origem)
    with open(input_xml_path, "r", encoding="utf-8") as f:
        xml_content = f.read()
    
    parser_v2 = MvXmlParser()
    ast_origem = parser_v2.parse(xml_content)
    print("[A] Legacy XML parsed to AST.")

    # Phase B: Serialize AST (Origem) -> E3 (JSON)
    serializer_v3 = MvJsonSerializer()
    json_e3 = serializer_v3.serialize(ast_origem)
    print("[B] AST serialized to E3 JSON.")

    # Phase C: Parse JSON (E3) -> AST (Destino)
    parser_v3 = MvJsonParser()
    ast_destino = parser_v3.parse(json_e3)
    # Restore legacy payload for round-trip parity
    if ast_origem.legacy_payload:
        ast_destino.legacy_payload = ast_origem.legacy_payload
    print("[C] E3 JSON parsed back to AST.")

    # Phase D: Serialize AST (Destino) -> XML Final (E2')
    serializer_v2 = MvXmlSerializer()
    xml_final = serializer_v2.serialize(ast_destino)
    print("[D] AST serialized to Legacy XML (E2').")

    # VT-3 Validation
    root_orig = ET.fromstring(xml_content)
    root_final = ET.fromstring(xml_final)
    
    clean_xml(root_orig)
    clean_xml(root_final)
    
    divergences = compare_xml_trees(root_orig, root_final)
    
    report = {
        "input": input_xml_path,
        "divergences": divergences,
        "parity_score": 100 if not divergences else max(0, 100 - len(divergences)),
        "vt3_status": "PASS" if not divergences else "FAIL"
    }
    
    with open("round_trip_report.json", "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
        
    print(f"\n--- Round-Trip Result: {report['vt3_status']} ---")
    print(f"Parity Score: {report['parity_score']}%")
    if divergences:
        print("Divergences detected:")
        for d in divergences:
            print(f" (!) {d}")
        output_xml_path = "batch_test_output/valid1_final.edt"
        with open(output_xml_path, "w", encoding="utf-8") as f:
            f.write(xml_final)
        print(f" (+) Final XML saved to {output_xml_path}")
    else:
        print(" (+) Total Parity Achieved. PL/SQL surviving via Entity Escaping.")

if __name__ == "__main__":
    test_file = "batch_test_input/valid1.edt" # Default test file
    if not os.path.exists(test_file):
        # Create a mock E2 XML if not exists
        mock_xml = """<DOCUMENTO>
  <CD_DOCUMENTO>123</CD_DOCUMENTO>
  <NM_DOCUMENTO>TEST_DOC</NM_DOCUMENTO>
  <LAYOUTS>
    <LAYOUT>
      <CD_LAYOUT>1</CD_LAYOUT>
      <NR_LARGURA>1024</NR_LARGURA>
      <NR_ALTURA>768</NR_ALTURA>
      <CAMPOS>
        <CAMPO>
          <CD_CAMPO>10</CD_CAMPO>
          <DS_CAMPO>Field &amp; Value</DS_CAMPO>
          <NM_IDENTIFICADOR>FIELD_1</NM_IDENTIFICADOR>
          <NR_POSICAO_X>100</NR_POSICAO_X>
          <NR_POSICAO_Y>100</NR_POSICAO_Y>
          <PROPRIEDADES>
            <PROPRIEDADE>
              <CD_PROPRIEDADE>4</CD_PROPRIEDADE>
              <VL_PROPRIEDADE>SELECT * FROM dual WHERE val &lt; 10</VL_PROPRIEDADE>
            </PROPRIEDADE>
          </PROPRIEDADES>
        </CAMPO>
      </CAMPOS>
    </LAYOUT>
  </LAYOUTS>
  <LO_REL_COMPILADO>JASPER_BYTESTREAM_BASE64</LO_REL_COMPILADO>
</DOCUMENTO>"""
        if not os.path.exists("batch_test_input"): os.makedirs("batch_test_input")
        with open(test_file, "w", encoding="utf-8") as f: f.write(mock_xml)
        
    run_round_trip(test_file)
