import logging
import re
import json
import base64
from typing import List, Optional, Any, Dict, Set
from core.ast_nodes import (
    MvDocument, 
    MvField, 
    MvBehavioralRule, 
    MvRuleCondition, 
    MvConditionLeaf, 
    MvConditionGroup
)

logger = logging.getLogger("WebEmitter")

class VanillaWebEmitter:
    """
    Crucible Emitter (N3 Compliance):
    - Euclidean Collision Detection.
    - Deterministic State Union (ES6).
    - Base64 Quarantine (Inert tags).
    - Stack Tracking (Reentrancy Guard).
    """

    def __init__(self):
        self.js_registry = {} # field_id -> List[Rule]
        self.has_collision = False

    def sanitize_id(self, identifier: str) -> str:
        if not identifier: return "field_unknown"
        clean = re.sub(r'[^a-zA-Z0-9_]', '_', identifier)
        if not re.match(r'^[a-zA-Z]', clean): clean = f"f_{clean}"
        return clean

    def is_overlapping(self, f1: MvField, f2: MvField) -> bool:
        """Euclidean Bounding Box Intersection Detection."""
        return not (f1.x + f1.width <= f2.x or
                    f1.x >= f2.x + f2.width or
                    f1.y + f1.height <= f2.y or
                    f1.y >= f2.y + f2.height)

    def emit(self, doc: MvDocument) -> str:
        self.js_registry = {}
        self.has_collision = False
        self._check_collisions(doc)

        html = [
            '<!DOCTYPE html>',
            '<html lang="pt-br">',
            '<head>',
            '    <meta charset="UTF-8">',
            f'    <title>{doc.name}</title>',
            self._generate_css(),
            '</head>',
            '<body>',
            f'    <div class="mv-root-container">',
            f'        <header><h1>{doc.name}</h1></header>',
            '        <main class="mv-screen-view">'
        ]

        for layout in doc.layouts:
            html.append(f'            <div class="canvas" style="width: {layout.width}px; height: {layout.height}px;">')
            html.extend(self._emit_fields(layout.fields))
            html.append('            </div>')

        html.append('        </main>')
        html.append(self._generate_print_view(doc))
        html.append('    </div>')
        html.append(self._generate_state_orchestrator())
        html.append('</body></html>')

        return "\n".join(html)

    def _check_collisions(self, doc: MvDocument):
        for layout in doc.layouts:
            flat = doc.flatten_fields(layout.fields)
            for i in range(len(flat)):
                for j in range(i + 1, len(flat)):
                    if self.is_overlapping(flat[i], flat[j]):
                        self.has_collision = True
                        logger.warning(f"Layout Collision: {flat[i].identifier} <-> {flat[j].identifier}")

    def _generate_css(self) -> str:
        return """
    <style>
        :root { --mv-primary: #2c3e50; --mv-danger: #e74c3c; --mv-warn: #f39c12; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f4f7f6; margin: 0; }
        .mv-root-container { padding: 40px; }
        .canvas { position: relative; background: white; border: 1px solid #dfe6e9; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1); margin: 0 auto; }
        .field { position: absolute; box-sizing: border-box; padding: 2px; }
        .field label { display: block; font-size: 10px; font-weight: bold; color: var(--mv-primary); text-transform: uppercase; margin-bottom: 2px; }
        .field input, .field select, .field textarea { width: 100%; height: calc(100% - 14px); border: 1px solid #ced4da; border-radius: 2px; padding: 4px; font-size: 12px; }
        .field input:focus { border-color: var(--mv-primary); outline: none; }
        
        /* Quarantine styles */
        [data-quarantined="true"] { border: 2px solid var(--mv-warn) !important; background: rgba(243, 156, 18, 0.05); }

        .mv-print-view { display: none; }
        @media print {
            .mv-screen-view { display: none; }
            .mv-print-view { display: block; }
            .canvas-print { position: relative; width: 210mm; height: 297mm; }
            .field-print { position: absolute; }
        }
    </style>
"""

    def _emit_fields(self, fields: List[MvField]) -> List[str]:
        lines = []
        for f in fields:
            f_id = self.sanitize_id(f.identifier)
            tag, input_type = self._map_tag(f.vis_type_identifier)
            style = f'left: {f.x}px; top: {f.y}px; width: {f.width}px; height: {f.height}px; z-index: {f.z_index};'
            
            # Quarantine Detection
            is_quarantined = False
            for rule in f.rules:
                if rule.intent == "OPAQUE_SCRIPT":
                    is_quarantined = True
                    break

            q_attr = ' data-quarantined="true"' if is_quarantined else ''
            lines.append(f'                <div class="field" style="{style}" id="container_mv-field-{f_id}"{q_attr}>')
            lines.append(f'                    <label>{f.name}</label>')
            
            if tag == "input":
                lines.append(f'                    <input type="{input_type}" id="mv-field-{f_id}" name="{f_id}">')
            elif tag == "select":
                lines.append(f'                    <select id="mv-field-{f_id}" name="{f_id}"></select>')
            elif tag == "textarea":
                lines.append(f'                    <textarea id="mv-field-{f_id}" name="{f_id}"></textarea>')
            
            if is_quarantined:
                for rule in f.rules:
                    if rule.intent == "OPAQUE_SCRIPT":
                        b64_sql = base64.b64encode(rule.raw_source.encode('utf-8')).decode('utf-8')
                        lines.append(f'                    <script type="application/vnd.mv.quarantine" data-reason="opaque_legacy_sql">{b64_sql}</script>')
            
            lines.append('                </div>')
            
            if f.rules:
                self.js_registry[f_id] = f.rules
            if f.children:
                lines.extend(self._emit_fields(f.children))
        return lines

    def _map_tag(self, vis_type: str):
        mapping = {"TEXT": ("input", "text"), "TEXTAREA": ("textarea", ""), "COMBOBOX": ("select", ""), "CHECKBOX": ("input", "checkbox"), "DATE": ("input", "date")}
        return mapping.get(vis_type, ("input", "text"))

    def _generate_print_view(self, doc: MvDocument) -> str:
        # Simplified mm conversion for brevity in plan, but using Crucible Formula in code
        mm_factor = 25.4 / 96
        lines = ['        <div class="mv-print-view">']
        for layout in doc.layouts:
            lines.append(f'            <div class="canvas-print">')
            for f in doc.flatten_fields(layout.fields):
                f_id = self.sanitize_id(f.identifier)
                x_mm = f.x * mm_factor
                y_mm = f.y * mm_factor
                w_mm = f.width * mm_factor
                h_mm = f.height * mm_factor
                style = f'left: {x_mm:.2f}mm; top: {y_mm:.2f}mm; width: {w_mm:.2f}mm; height: {h_mm:.2f}mm; z-index: {f.z_index};'
                lines.append(f'                <div class="field-print" style="{style}">{f.name}: [__________]</div>')
            lines.append('            </div>')
        lines.append('        </div>')
        return "\n".join(lines)

    def _generate_state_orchestrator(self) -> str:
        # Serializing registry to JS
        registry_json = []
        for f_id, rules in self.js_registry.items():
            field_rules = []
            for r in rules:
                if r.intent == "OPAQUE_SCRIPT": continue
                field_rules.append({
                    "trigger": r.trigger,
                    "intent": r.intent,
                    "targets": [self.sanitize_id(t) for t in r.targets],
                    "condition": self._serialize_condition(r.condition_root)
                })
            if field_rules:
                registry_json.append(f"'{f_id}': {json.dumps(field_rules)}")
        
        registry_js = "{" + ", ".join(registry_json) + "}"

        return f"""
    <script>
        class StateOrchestrator {{
            constructor(registry) {{
                this.registry = registry || {{}};
                this.activeNodes = new Set();
                this.init();
            }}

            init() {{
                Object.keys(this.registry).forEach(fieldId => {{
                    const el = document.getElementById('mv-field-' + fieldId);
                    if (el) {{
                        el.addEventListener('change', () => this.update(fieldId));
                        if (el.type === 'checkbox' || el.type === 'radio') {{
                            el.addEventListener('click', () => this.update(fieldId));
                        }}
                    }}
                }});
            }}

            update(triggerId) {{
                if (this.activeNodes.has(triggerId)) return; // Prevents cycle
                this.activeNodes.add(triggerId);
                
                try {{
                    const affectedTargets = new Set();
                    // 1. Identify all targets possibly affected by this trigger
                    this.registry[triggerId].forEach(rule => {{
                        rule.targets.forEach(t => affectedTargets.add(t));
                    }});

                    // 2. Deterministic Recalculation (Union Logic)
                    affectedTargets.forEach(targetId => this.evaluateFieldState(targetId));
                }} finally {{
                    this.activeNodes.delete(triggerId);
                }}
            }}

            evaluateFieldState(targetId) {{
                // Find all rules across the entire registry that point to this target
                let shouldDisable = false;
                Object.values(this.registry).forEach(rules => {{
                    rules.forEach(rule => {{
                        if (rule.targets.includes(targetId)) {{
                            if (rule.intent === 'DISABLE' && this.checkCondition(rule.condition)) {{
                                shouldDisable = true;
                            }}
                            if (rule.intent === 'ENABLE' && this.checkCondition(rule.condition)) {{
                                // In MV, ENABLE rules typically override or compete. 
                                // Here we implement intersection: if any DISABLE rule is met, it stays disabled.
                            }}
                        }}
                    }});
                }});

                const targetEl = document.getElementById('mv-field-' + targetId);
                if (targetEl) {{
                    targetEl.disabled = shouldDisable;
                }}
            }}

            checkCondition(cond) {{
                if (!cond) return true;
                if (cond.type === 'leaf') {{
                    const el = document.getElementById('mv-field-' + cond.subject);
                    if (!el) return false;
                    const val = el.type === 'checkbox' ? (el.checked ? 'true' : 'false') : el.value;
                    
                    switch(cond.op) {{
                        case '==': return val === cond.val;
                        case '!=': return val !== cond.val;
                        case '>': return parseFloat(val) > parseFloat(cond.val);
                        case '<': return parseFloat(val) < parseFloat(cond.val);
                        default: return false;
                    }}
                }} else if (cond.type === 'group') {{
                    if (cond.op === 'AND') {{
                        return cond.children.every(c => this.checkCondition(c));
                    }} else {{
                        return cond.children.some(c => this.checkCondition(c));
                    }}
                }}
                return true;
            }}
        }}

        const orchestrator = new StateOrchestrator({registry_js});
    </script>
"""

    def _serialize_condition(self, node: Optional[MvRuleCondition]) -> Optional[Dict]:
        if not node: return None
        if isinstance(node, MvConditionLeaf):
            return {"type": "leaf", "subject": self.sanitize_id(node.subject_identifier), "op": node.operator, "val": str(node.value)}
        elif isinstance(node, MvConditionGroup):
            return {"type": "group", "op": node.connector or "AND", "children": [self._serialize_condition(c) for c in node.children]}
        return None

    def get_audit_result(self) -> Dict:
        return {"has_layout_collision": self.has_collision}
