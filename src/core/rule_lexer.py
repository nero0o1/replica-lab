import re
import logging
from typing import List, Dict, Optional, Any
from core.ast_nodes import (
    MvBehavioralRule, 
    MvRuleCondition, 
    MvConditionLeaf, 
    MvConditionGroup
)

logger = logging.getLogger("RuleLexer")

class RuleLexer:
    SYSTEM_VAR_PATTERN = re.compile(r"&<(.*?)>")
    COMPLEX_SQL_KEYWORDS = ["DECLARE", "BEGIN", "CURSOR", "LOOP", "OPEN", "FETCH"]
    
    def __init__(self, id_to_identifier_map: Dict[int, str]):
        self.id_map = id_to_identifier_map

    def parse_e3_rule(self, rule_data: Dict[str, Any]) -> MvBehavioralRule:
        rule_id = str(rule_data.get("id", ""))
        trigger = rule_data.get("ruleType", {}).get("identifier", "UNKNOWN")
        intent = trigger
        raw_action = rule_data.get("actionString", "")
        if any(keyword in raw_action.upper() for keyword in self.COMPLEX_SQL_KEYWORDS):
            intent = "OPAQUE_SCRIPT"

        mv_rule = MvBehavioralRule(
            identifier=rule_data.get("identifier") or f"RULE_{rule_id}",
            trigger=trigger,
            intent=intent
        )
        mv_rule.raw_source = self.SYSTEM_VAR_PATTERN.sub(r"{{SYSTEM_VAR:\1}}", raw_action)
        target_info = rule_data.get("ruleFieldDTOS")
        if target_info:
            target_id = target_info.get("fieldId")
            mv_rule.targets.append(self._resolve_id(target_id, target_info.get("fieldIdentifier")))
        cond_data = rule_data.get("ruleConditionDTOS")
        if cond_data:
            mv_rule.condition_root = self._parse_recursive_conditions(cond_data)
        return mv_rule

    def _parse_recursive_conditions(self, cond_data: Dict[str, Any]) -> MvRuleCondition:
        children_data = cond_data.get("ruleChildrensConditions")
        connector = cond_data.get("ruleConnectorIdentifier")
        if children_data and len(children_data) > 0:
            group = MvConditionGroup(connector=connector)
            if cond_data.get("fieldId"):
                group.add_child(self._create_leaf(cond_data))
            for child in children_data:
                group.add_child(self._parse_recursive_conditions(child))
            return group
        return self._create_leaf(cond_data)

    def _create_leaf(self, c_data: Dict[str, Any]) -> MvConditionLeaf:
        f_id = c_data.get("fieldId")
        subject_ident = self._resolve_id(f_id, c_data.get("fieldIdentifier"))
        return MvConditionLeaf(
            subject_identifier=subject_ident,
            operator=c_data.get("ruleOperatorIdentifier", "=="),
            value=str(c_data.get("value", "")),
            connector=c_data.get("ruleConnectorIdentifier")
        )

    def _resolve_id(self, numeric_id: Optional[int], identifier_hint: Optional[str]) -> str:
        if numeric_id is not None and numeric_id in self.id_map:
            return self.id_map[numeric_id]
        return identifier_hint or str(numeric_id)
