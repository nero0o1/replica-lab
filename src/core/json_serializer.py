import json
from typing import Dict, Any
from core.ast_nodes import MvDocument, MvLayout, MvField, MvProperty, MvBehavioralRule

class MvJsonSerializer:
    """
    Editor 3 JSON Serializer:
    - Encodes AST to modern E3 format.
    - Uses Rosetta Stone mapping for properties.
    """

    def serialize(self, doc: MvDocument) -> str:
        data = {
            "id": doc.id,
            "name": doc.name,
            "version": "3.0",
            "data": {
                "identifier": doc.identifier,
                "document_properties": {p.id: p.value for p in doc.property_document_values if p.id},
                "layouts": [self._serialize_layout(l) for l in doc.layouts]
            }
        }
        return json.dumps(data, indent=2, ensure_ascii=False)

    def _serialize_layout(self, layout: MvLayout) -> Dict[str, Any]:
        return {
            "id": layout.id,
            "name": layout.name,
            "width": layout.width,
            "height": layout.height,
            "fields": [self._serialize_field(f) for f in layout.fields]
        }

    def _serialize_field(self, field: MvField) -> Dict[str, Any]:
        f_data = {
            "id": field.id,
            "name": field.name,
            "identifier": field.identifier,
            "x": field.x,
            "y": field.y,
            "width": field.width,
            "height": field.height,
            "properties": {p.id: p.value for p in field.properties if p.id},
            "rules": [self._serialize_rule(r) for r in field.rules],
            "children": [self._serialize_field(c) for c in field.children]
        }
        return f_data

    def _serialize_rule(self, rule: MvBehavioralRule) -> Dict[str, Any]:
        return {
            "identifier": rule.identifier,
            "trigger": rule.trigger,
            "intent": rule.intent,
            "targets": rule.targets,
            "terminal": rule.terminal,
            "raw_source": rule.raw_source,
            "condition_root": self._serialize_condition(rule.condition_root) if rule.condition_root else None
        }

    def _serialize_condition(self, node: MvRuleCondition) -> Dict[str, Any]:
        from core.ast_nodes import MvConditionLeaf, MvConditionGroup
        data = {"connector": node.connector}
        if isinstance(node, MvConditionLeaf):
            data.update({
                "type": "leaf",
                "subject": node.subject_identifier,
                "operator": node.operator,
                "value": node.value
            })
        elif isinstance(node, MvConditionGroup):
            data.update({
                "type": "group",
                "children": [self._serialize_condition(c) for c in node.children]
            })
        return data
