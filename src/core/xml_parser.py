import xml.etree.ElementTree as ET
from typing import List, Optional
from core.ast_nodes import MvDocument, MvLayout, MvField, MvProperty, MvBehavioralRule, MvLegacyPayload
from core.etiquetas_semanticas import obter_etiqueta

class MvXmlParser:
    """
    Editor 2 XML Parser:
    - Transpiles Legacy E2 XML to MvDocument AST.
    - Handles nested fields and properties.
    - Preserves Jasper blobs in MvLegacyPayload.
    """

    def parse(self, xml_content: str) -> MvDocument:
        root = ET.fromstring(xml_content)
        doc_name = root.findtext("NM_DOCUMENTO", "Untitled Document")
        doc = MvDocument(doc_name)
        
        doc_id = root.findtext("CD_DOCUMENTO")
        if doc_id: doc.id = int(doc_id)
        
        doc.identifier = root.findtext("NM_IDENTIFICADOR")
        
        # Document Properties
        for prop_node in root.findall("PROPRIEDADES/PROPRIEDADE"):
            doc.property_document_values.append(self._parse_property(prop_node))
            
        # Layouts
        for layout_node in root.findall("LAYOUTS/LAYOUT"):
            doc.layouts.append(self._parse_layout(layout_node))
            
        # Vault Extraction
        jasper_blob = root.findtext("LO_REL_COMPILADO")
        if jasper_blob:
            doc.legacy_payload = MvLegacyPayload(jasper_blob, "JASPER")
            
        return doc

    def _parse_layout(self, node: ET.Element) -> MvLayout:
        layout = MvLayout()
        layout_id = node.findtext("CD_LAYOUT")
        if layout_id: layout.id = int(layout_id)
        
        layout.name = node.findtext("DS_LAYOUT")
        layout.width = int(node.findtext("NR_LARGURA", "1024"))
        layout.height = int(node.findtext("NR_ALTURA", "768"))
        
        for field_node in node.findall("CAMPOS/CAMPO"):
            layout.fields.append(self._parse_field(field_node))
            
        return layout

    def _parse_field(self, node: ET.Element) -> MvField:
        field = MvField()
        f_id = node.findtext("CD_CAMPO")
        if f_id: field.id = int(f_id)
        
        field.name = node.findtext("DS_CAMPO")
        field.identifier = node.findtext("NM_IDENTIFICADOR")
        field.x = int(node.findtext("NR_POSICAO_X", "0"))
        field.y = int(node.findtext("NR_POSICAO_Y", "0"))
        field.width = int(node.findtext("NR_LARGURA", "150"))
        field.height = int(node.findtext("NR_ALTURA", "30"))
        
        # Properties
        for prop_node in node.findall("PROPRIEDADES/PROPRIEDADE"):
            field.properties.append(self._parse_property(prop_node))
            
        # Nested Fields
        for child_node in node.findall("CAMPOS_FILHOS/CAMPO"):
            field.children.append(self._parse_field(child_node))
            
        return field

    def _parse_property(self, node: ET.Element) -> MvProperty:
        p_id = int(node.findtext("CD_PROPRIEDADE", "0"))
        p_identifier = obter_etiqueta(p_id)
        val = node.findtext("VL_PROPRIEDADE")
        
        # S/N to Boolean
        if val == "S": val = True
        elif val == "N": val = False
        
        return MvProperty(p_id, p_identifier, val)
