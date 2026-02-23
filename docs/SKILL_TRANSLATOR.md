# SKILL_TRANSLATOR: Guia para Agentes e IA

Este documento define regras léxicas e constantes que devem ser seguidas rigorosamente por qualquer inteligência artificial que opere neste código.

## 1. Regras Imutáveis de Prefixo
Nunca renomeie ou tente "estetizar" identificadores técnicos internos. Os prefixos abaixo são sinais vitais para o interpretador hospitalar:
- `RDB_`: Radio Button Group.
- `CHB_`: Checkbox.
- `TXT_`: Text/Memo Field.
- `LST_`: List/Combo Box.

## 2. Constantes Globais (CD_PROPRIEDADE)
Nunca utilize números puros (Magic Numbers) no código. Sempre utilize as constantes mapeadas do dicionário MV:

| Constante | ID | Significado Oficial |
| :--- | :--- | :--- |
| `CDP_01` | 1 | TAMANHO |
| `CDP_02` | 2 | LISTA_VALORES |
| `CDP_03` | 3 | MASCARA |
| `CDP_04` | 4 | ACAO |
| `CDP_05` | 5 | USADO_EM |
| `CDP_07` | 7 | EDITAVEL |
| `CDP_08` | 8 | OBRIGATORIO |
| `CDP_09` | 9 | VALOR_INICIAL |
| `CDP_10` | 10 | CRIADO_POR |
| `CDP_15` | 15 | COMPRIMENTO_MAXIMO |
| `CDP_17` | 17 | REPROCESSAR |
| `CDP_21` | 21 | ACAO_SQL |
| `CDP_25` | 25 | ESTRUTURA_LISTA |
| `CDP_38` | 38 | CASCATA_DE_REGRA |
| `CDP_43` | 43 | VERSAO_ESTRUTURAL |

**Nota**: A lista acima cobre os IDs críticos concluídos. O intervalo de 1 a 43 deve ser mantido fixo.
