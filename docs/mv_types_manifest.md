# MANIFESTO DE TIPOS (PROTOCOL_MV_NATIVE)

Este documento mapeia os IDs numéricos (CD_TIPO_VISUALIZACAO) para seus componentes visuais correspondentes, conforme a "Lei dos IDs Numéricos".

## Tabela Mestra de IDs

| ID (CD_TIPO) | Componente Visual | Descrição / Comportamento |
| :--- | :--- | :--- |
| **1** | **TEXTO (Input)** | Campo de entrada de texto simples. |
| **2** | **LISTA (Array)** | Lista de valores moderna (JSON Array). |
| **4** | **AÇÃO (Botão)** | Botão ou gatilho para execução de scripts/SQL. |
| **8** | **CHECKBOX (Obrigatório)** | Visualização de booleano (Flag de Obrigatoriedade). |
| **17** | **FLAG (Editável)** | Visualização de booleano (Flag de Edição). |
| **25** | **LISTA LEGADO** | Lista de valores antiga (String separada por pipes `|`). |
| **31** | **DESCRIÇÃO API** | Metadado descritivo para integração.. |
| **35** | **GRID (Tabela)** | Tabela complexa de dados (*Conforme Prompt*). |
| **43** | **UNKNOWN** | *Observado em logs, funcão a confirmar.* |

## Regras de Interpretação
1. **Zero Inferência**: Se um campo se chama `TXT_NOME` mas tem ID 4, ele É UM BOTÃO. O nome é irrelevante.
2. **Prioridade**: O interpretador deve sempre carregar o componente baseado nesta tabela antes de aplicar quaisquer propriedades.
