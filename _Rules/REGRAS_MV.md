# Relatório de Extração Comportamental (Behavioral Patterns)

Este documento consolida os padrões lógicos extraídos das amostras de campo (`.edt` e JSON) para fundamentar o `RuleLexer`.

## 1. Mapeamento de Gatilhos (Triggers)

| Token Identificado | Contexto Operacional (Legacy Hook) | Descrição |
|:---:|---|---|
| `ON_CHANGE` | `ruleType: 1` (ANSWER/ENABLE/...) | Disparado ao modificar o valor do campo. |
| `ON_LOAD` | `executar_regra_ao_carregar: true` | Executado na inicialização do formulário. |
| `IS_CLICK` | `ruleOperatorIdentifier: "is clicked"` | Específico para botões ou componentes de ação direta. |
| `ON_SAVE` | `ruleType: 1001` | Regras de validação de persistência. |
| `ON_PRINT` | `ruleType: 1004` | Regras de formatação ou filtragem de saída. |

## 2. Inventário de Intenções (Intents)

| Intent | Ação no Alvo (Target) | Exemplo de Uso |
|:---:|---|---|
| `ENABLE` | Ativa interatividades | Habilitar "Motivo" se "Outros" for selecionado. |
| `DISABLE` | Bloqueia interatividade | Desabilitar campo se o status for "Finalizado". |
| `VALIDATE` | Bloqueio de fluxo | Impedir salvamento se data for superior a hoje. |
| `NOTIFY` | Feedback visual | Exibir mensagem de sucesso/erro via JSON Payload. |
| `FETCH_SQL` | População dinâmica | Carregar ComboBox baseado em filtro de ID anterior. |

## 3. Gramática de Condições (Operators)

Ficou evidenciada a suporte a árvores de decisão recursivas com conectores:
- **Operadores Relacionais**: `==`, `!=`, `>`, `<`, `>=`, `<=`.
- **Conectores Lógicos**: `AND` (E), `OR` (OU).
- **Aninhamento**: Suporte a `ruleChildrensConditions` permitindo lógica complexa `(A e B) ou (C e D)`.

## 4. Variáveis Protegidas (System Macro)

Identificamos a necessidade de isolar os seguintes padrões via Lexer:
- `&<PAR_CD_ATENDIMENTO>`
- `&<PAR_USUARIO_LOGADO>`
- `&<PAR_CD_PACIENTE>`

---
> [!IMPORTANT]
> A `Behavioral AST` agora armazena estes padrões de forma neutra, resolvendo IDs para Identificadores Literais, o que permite o "Deep Re-Engineering" do documento para qualquer plataforma alvo.


# Relatório de Design: Motor Behavioral AST & RuleLexer

Para transformar o "ReplicaEditor" em um Tradutor Universal, estamos elevando a AST do nível puramente estrutural (X,Y) para o nível semântico e comportamental.

## 1. Padrões Extraídos (Mapeamento de Regras)

Com base na análise dos artefatos (incluindo `5.documents_COMBO_TESTE0.edt` e os metadados de primitivos), identificamos os seguintes blocos lógicos:

| Categoria | Tokens / Padrões Identificados |
|:---:|---|
| **Triggers (Gatilhos)** | `ANSWER`, `ON_CHANGE`, `IS_CLICK`, `ON_LOAD` (`executar_regra_ao_carregar`), `ON_SAVE`, `ON_PRINT`. |
| **Intents (Ações)** | `ENABLE` (Habilitar), `DISABLE` (Desabilitar), `VALIDATE` (Validar/Answer), `NOTIFY` (Notificar), `FILTER` (Filtrar), `REFRESH_FIELD`. |
| **Operadores** | `==` (equal to), `!=` (different from), `>` (bigger than), `<` (less than), `IS_CLICK`. |
| **Macros/Session** | Padrões como `&<PAR_VARIABLE>` encontrados em campos de `acao` (SQL). |

## 2. Abordagem Técnica do RuleLexer

O `rule_lexer.py` será construído sobre quatro pilares de segurança:

### A. Resolução Semântica de Referências
O Lexer não operará sobre "IDs Órfãos". Durante a tokenização de um `Target`, o Lexer consultará o `MvDocument` para traduzir o ID numérico (ex: `3251`) para o Identificador literal (ex: `TEXTO`). Isso garante que a AST resultante seja portável para sistemas que não compartilham a mesma sequência de banco de dados do MV.

### B. Mapeamento de Lifecycle
Mapearemos os IDs de `ruleType` para ENUMS de ciclo de vida:
- **Pre-Processing**: `onLoad`, `onCreate`.
- **Interaction**: `onChange`, `onClick`.
- **Post-Processing**: `onSave`, `onClose`, `onPrint`.

### C. Gestão de Cascata (Loop Prevention)
Utilizaremos a propriedade `cascata_de_regra` (ID 38) para marcar tokens de ação. Se `cascata == false`, o Lexer injetará um flag `TERMINAL` na `MvBehavioralRule`. Isso instruirá tradutores futuros (JS, Python) a não dispararem eventos de mudança recursivos.

### D. Protected Variable Tokenization
Criaremos um token especial `SystemVariableToken` (Regex: `&<.*?>`).
- **Objetivo**: Evitar que o `<` e `&` sejam confundidos com delimitadores XML ou operadores lógicos durante a serialização. Na AST, eles serão objetos de primeira classe: `SystemVariable(name="PAR_CD_ATENDIMENTO")`.

## 3. Estrutura da MvBehavioralRule (ast_nodes.py)

A nova classe será estruturada para suportar composições complexas (AND/OR):

```python
class MvBehavioralRule:
    def __init__(self, trigger: str, intent: str, targets: List[str], raw_logic: str):
        self.trigger = trigger     # Ex: "ON_CHANGE"
        self.intent = intent       # Ex: "ENABLE"
        self.targets = targets     # List["IDENTIFIER_A", "IDENTIFIER_B"]
        self.conditions = []       # List[MvRuleCondition]
        self.terminal = True       # Based on Property 38
        self.raw_source = raw_logic
```

---
> [!NOTE]
> Esta camada abstrai a "lógica louca" permitindo que, no futuro, o mesmo documento possa renderizar um `onChange` em React ou uma `Rule` em Oracle Forms com a mesma base de conhecimento.
