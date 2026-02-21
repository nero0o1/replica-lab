import json
from typing import Dict, Any
from core.ast_nodes import MvDocument, MvLayout, MvField, MvProperty

class MvJsonParser:
    """
    Editor 3 JSON Parser:
    - Reconstructs AST from modern E3 JSON.
    """

    def parse(self, json_content: str) -> MvDocument:
        raw = json.loads(json_content)
        doc = MvDocument(raw["name"])
        doc.id = raw.get("id")
        data = raw.get("data", {})
        doc.identifier = data.get("identifier")
        
        doc_props = data.get("document_properties", {})
        for p_id, p_val in doc_props.items():
            doc.property_document_values.append(MvProperty(int(p_id), "", p_val))

        for l_data in data.get("layouts", []):
            doc.layouts.append(self._parse_layout(l_data))
            
        return doc

    def _parse_layout(self, data: Dict[str, Any]) -> MvLayout:
        layout = MvLayout()
        layout.id = data.get("id")
        layout.name = data.get("name")
        layout.width = data.get("width", 1024)
        layout.height = data.get("height", 768)
        
        for f_data in data.get("fields", []):
            layout.fields.append(self._parse_field(f_data))
            
        return layout

    def _parse_field(self, data: Dict[str, Any]) -> MvField:
        field = MvField()
        field.id = data.get("id")
        field.name = data.get("name")
        field.identifier = data.get("identifier")
        field.x = data.get("x", 0)
        field.y = data.get("y", 0)
        field.width = data.get("width")
        field.height = data.get("height")
        
        props = data.get("properties", {})
        for p_id, p_val in props.items():
            field.properties.append(MvProperty(int(p_id), "", p_val))
            
        for r_data in data.get("rules", []):
            field.rules.append(self._parse_rule(r_data))

        for c_data in data.get("children", []):
            field.children.append(self._parse_field(c_data))
            
        return field

    def _parse_rule(self, data: Dict[str, Any]) -> MvBehavioralRule:
        from core.ast_nodes import MvBehavioralRule
        rule = MvBehavioralRule(
            identifier=data["identifier"],
            trigger=data["trigger"],
            intent=data["intent"]
        )
        rule.targets = data.get("targets", [])
        rule.terminal = data.get("terminal", True)
        rule.raw_source = data.get("raw_source")
        if data.get("condition_root"):
            rule.condition_root = self._parse_condition(data["condition_root"])
        return rule

    def _parse_condition(self, data: Dict[str, Any]) -> Any:
        from core.ast_nodes import MvConditionLeaf, MvConditionGroup
        connector = data.get("connector")
        if data["type"] == "leaf":
            return MvConditionLeaf(
                subject_identifier=data["subject"],
                operator=data["operator"],
                value=data["value"],
                connector=connector
            )
        elif data["type"] == "group":
            group = MvConditionGroup(connector=connector)
            for child_data in data.get("children", []):
                group.add_child(self._parse_condition(child_data))
            return group
        return None
