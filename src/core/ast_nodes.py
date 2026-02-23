from typing import List, Optional, Dict, Any
from core.etiquetas_semanticas import PropId

class MvLegacyPayload:
    """Vault for binary data that must be preserved but not parsed (e.g. Jasper blobs)."""
    def __init__(self, raw_content: str, payload_type: str = "JASPER"):
        self.raw_content = raw_content
        self.payload_type = payload_type

class MvProperty:
    def __init__(self, property_id: int, identifier: str, value: Any, hash_val: Optional[str] = None):
        self.id = property_id
        self.identifier = identifier
        self.value = value
        self.hash = hash_val

class MvRuleCondition:
    """Base class for Composite Pattern in rule conditions."""
    def __init__(self, connector: Optional[str] = None):
        self.connector = connector # AND / OR

class MvConditionLeaf(MvRuleCondition):
    """Leaf node for a single evaluation (e.g., FieldA == 'S')."""
    def __init__(self, subject_identifier: str, operator: str, value: str, connector: Optional[str] = None):
        super().__init__(connector)
        self.subject_identifier = subject_identifier
        self.operator = operator
        self.value = value

class MvConditionGroup(MvRuleCondition):
    """Composite node for nested logical blocks."""
    def __init__(self, connector: Optional[str] = None):
        super().__init__(connector)
        self.children: List[MvRuleCondition] = []

    def add_child(self, child: MvRuleCondition):
        self.children.append(child)

class MvBehavioralRule:
    def __init__(self, identifier: str, trigger: str, intent: str):
        self.identifier = identifier
        self.trigger = trigger     # Ex: "ON_CHANGE", "ON_LOAD"
        self.intent = intent       # Ex: "ENABLE", "DISABLE", "VALIDATE", "OPAQUE_SCRIPT"
        self.targets: List[str] = []
        self.condition_root: Optional[MvRuleCondition] = None
        self.terminal: bool = True # Based on cascata_de_regra (PropId.CASCATA_DE_REGRA = 38)
        self.raw_source: Optional[str] = None

class MvField:
    def __init__(self):
        self.id: Optional[int] = None
        self.name: Optional[str] = None
        self.identifier: Optional[str] = None
        self.type_id_legacy: Optional[int] = 0
        self.vis_type_identifier: Optional[str] = None
        self.x: int = 0
        self.y: int = 0
        self.width: int = 150
        self.height: int = 30
        self.z_index: int = 0
        self.properties: List[MvProperty] = []
        self.rules: List[MvBehavioralRule] = []
        self.children: List['MvField'] = []
        self.root_hash: Optional[str] = None

class MvLayout:
    def __init__(self):
        self.id: Optional[int] = None
        self.name: Optional[str] = None
        self.width: int = 1024
        self.height: int = 768
        self.fields: List[MvField] = []

class MvDocument:
    @staticmethod
    def sanitize_identifier(identifier: str) -> str:
        """Regra do Crachá: Força padronização UPPER_SNAKE_CASE para IDs técnicos."""
        if not identifier: return "UNNAMED_ID"
        # 1. Transformar em maiúsculas
        clean = identifier.upper().strip()
        # 2. Substituir espaços e hifens por sublinhados
        clean = re.sub(r'[^A-Z0-9_]', '_', clean)
        # 3. Remover sublinhados duplicados e nas extremidades
        clean = re.sub(r'_+', '_', clean).strip('_')
        return clean

    def __init__(self, name: str):
        self.id: Optional[int] = None
        self.name: str = name
        self.identifier: Optional[str] = None
        self.active: bool = True
        self.layouts: List[MvLayout] = []
        self.property_document_values: List[MvProperty] = []
        self.legacy_payload: Optional[MvLegacyPayload] = None

    def validate_dependency_graph(self):
        """
        Anti-Loop: Detects circular dependencies in rules.
        A -> B -> A loops are flagged.
        """
        adj = {}
        # 1. Build Adjacency List (Subject -> Targets)
        for layout in self.layouts:
            for field in self.flatten_fields(layout.fields):
                for rule in field.rules:
                    subjects = self._extract_subjects(rule.condition_root)
                    for sj in subjects:
                        if sj not in adj: adj[sj] = set()
                        for target in rule.targets:
                            adj[sj].add(target)
        
        # 2. DFS for Cycles
        visited = set()
        path = set()
        
        def has_cycle(u):
            visited.add(u)
            path.add(u)
            for v in adj.get(u, []):
                if v in path: return True
                if v not in visited:
                    if has_cycle(v): return True
            path.remove(u)
            return False

        for node in adj:
            if node not in visited:
                if has_cycle(node):
                    print(f"(!) CRITICAL: Circular Dependency Detected involving field '{node}'")
                    return False
        return True

    def _extract_subjects(self, node: Optional[MvRuleCondition]) -> List[str]:
        if not node: return []
        subjects = []
        if isinstance(node, MvConditionLeaf):
            subjects.append(node.subject_identifier)
        elif isinstance(node, MvConditionGroup):
            for child in node.children:
                subjects.extend(self._extract_subjects(child))
        return subjects

    def flatten_fields(self, fields: List[MvField]) -> List[MvField]:
        flat = []
        for f in fields:
            flat.append(f)
            flat.extend(self.flatten_fields(f.children))
        return flat

class Onda1Foundation:
    """Class representing the strict 'Wave 1' foundation structure."""
    def __init__(self, nome: str, identificador: str, tipo: str, grupo: str):
        self.Nome = nome
        self.Identificador = identificador
        self.Tipo = tipo
        self.Grupo = grupo
        self.Dados: Dict[str, Any] = {}
        self.Versão: str = "1.0.0"
        self.Layout: Dict[str, Any] = {}

    def to_dict(self) -> Dict[str, Any]:
        """Returns the foundation as a dictionary maintaining strict key order."""
        from collections import OrderedDict
        d = OrderedDict()
        d["Nome"] = self.Nome
        d["Identificador"] = self.Identificador
        d["Tipo"] = self.Tipo
        d["Grupo"] = self.Grupo
        d["Dados"] = self.Dados
        d["Versão"] = self.Versão
        d["Layout"] = self.Layout
        return d
