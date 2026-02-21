import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape
from typing import Optional, Any
from core.ast_nodes import MvDocument, MvField, MvLayout, MvProperty, MvLegacyPayload

class MvXmlSerializer:
    """
    High-Fidelity Editor 2 XML Serializer:
    - Null-Space Insertion: Omits ID tags for new entities to trigger Oracle Sequences.
    - Win-1252 Safe-Encode: Bridges Modern Unicode and Legacy encoding.
    - S/N Coercion: Boolean parity for Oracle VARCHAR(1).
    - Vault Restoration: Reinjection of Jasper blobs.
    """

    def __init__(self):
        # Empty structural Jasper blob (Fall-back)
        self.EMPTY_JASPER = "MQ== " # Mock Base64 for a structural empty jasper stream

    def serialize(self, doc: MvDocument) -> str:
        root = ET.Element("DOCUMENTO")
        
        if doc.id:
            ET.SubElement(root, "CD_DOCUMENTO").text = str(doc.id)
            
        ET.SubElement(root, "NM_DOCUMENTO").text = self._safe_encode(doc.name)
        
        if doc.identifier:
            ET.SubElement(root, "NM_IDENTIFICADOR").text = self._safe_encode(doc.identifier)
        
        # Document Properties
        props_node = ET.SubElement(root, "PROPRIEDADES")
        for p in doc.property_document_values:
            self._serialize_property(props_node, p)
            
        # Layouts
        layouts_node = ET.SubElement(root, "LAYOUTS")
        for layout in doc.layouts:
            self._serialize_layout(layouts_node, layout)
            
        # Vault Restoration
        jasper_node = ET.SubElement(root, "LO_REL_COMPILADO")
        if doc.legacy_payload and doc.legacy_payload.payload_type == "JASPER":
            jasper_node.text = doc.legacy_payload.raw_content
        else:
            jasper_node.text = self.EMPTY_JASPER
            
        return self._prettify(root)

    def _serialize_layout(self, parent: ET.Element, layout: MvLayout):
        node = ET.SubElement(parent, "LAYOUT")
        if layout.id:
            ET.SubElement(node, "CD_LAYOUT").text = str(layout.id)
        
        if layout.name:
            ET.SubElement(node, "DS_LAYOUT").text = self._safe_encode(layout.name)
        
        ET.SubElement(node, "NR_LARGURA").text = str(layout.width)
        ET.SubElement(node, "NR_ALTURA").text = str(layout.height)
        
        fields_node = ET.SubElement(node, "CAMPOS")
        # Zen-Ordering: Sort by z_index to ensure depth integrity
        sorted_fields = sorted(layout.fields, key=lambda f: f.z_index)
        for field in sorted_fields:
            self._serialize_field(fields_node, field)

    def _serialize_field(self, parent: ET.Element, field: MvField):
        node = ET.SubElement(parent, "CAMPO")
        
        # Null-Space: Omit tag if id is missing
        if field.id:
            ET.SubElement(node, "CD_CAMPO").text = str(field.id)
        
        ET.SubElement(node, "DS_CAMPO").text = self._safe_encode(field.name or "")
        ET.SubElement(node, "NM_IDENTIFICADOR").text = self._safe_encode(field.identifier or "")
        ET.SubElement(node, "NR_POSICAO_X").text = str(field.x)
        ET.SubElement(node, "NR_POSICAO_Y").text = str(field.y)
        ET.SubElement(node, "NR_LARGURA").text = str(field.width or 0)
        ET.SubElement(node, "NR_ALTURA").text = str(field.height or 0)
        
        props_node = ET.SubElement(node, "PROPRIEDADES")
        for p in field.properties:
            self._serialize_property(props_node, p)
            
        if field.children:
            child_node = ET.SubElement(node, "CAMPOS_FILHOS")
            for child in field.children:
                self._serialize_field(child_node, child)

    def _serialize_property(self, parent: ET.Element, prop: MvProperty):
        node = ET.SubElement(parent, "PROPRIEDADE")
        
        # Null-Space Insertion
        if prop.id:
            ET.SubElement(node, "CD_PROPRIEDADE").text = str(prop.id)
            
        val = prop.value
        # S/N Coercion
        if isinstance(val, bool):
            val = "S" if val else "N"
        
        # ET handles escaping automatically.
        ET.SubElement(node, "VL_PROPRIEDADE").text = self._safe_encode(str(val or ""))

    def _safe_encode(self, text: str) -> str:
        """TypeCaster: Win-1252 Bridge with Crash Prevention."""
        try:
            # Bridging to Win-1252 and back to string to ensure compatibility
            return text.encode('windows-1252', errors='replace').decode('windows-1252')
        except Exception:
            return ""

    def _prettify(self, element: ET.Element) -> str:
        """Returns a stable, pretty-printed XML string."""
        from xml.dom import minidom
        rough_string = ET.tostring(element, 'utf-8')
        reparsed = minidom.parseString(rough_string)
        return reparsed.toprettyxml(indent="  ")
