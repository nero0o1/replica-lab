# Dossiê 15: Dicionário de Etiquetas Semânticas

## 1. Propósito e Importância
Este documento define as regras de tradução para eliminar "Magic Numbers" do sistema. A utilização de números crus como `8` para representar "Obrigatoriedade" é uma prática legada que gera dívida técnica e erros de interpretação.

A importância desta regra reside no **alinhamento de domínio**: desenvolvedores e sistemas devem se comunicar através de termos semânticos (`obrigatorio`, `editavel`) que descrevem a função da propriedade, não o seu índice arbitrário no banco de dados.

## 2. Regras de Desenvolvimento (Code Rules)
1.  **Proibição de Magic Numbers**: É estritamente proibido o uso de literais numéricos para referenciar propriedades de campo em qualquer novo código (Python ou PowerShell).
2.  **Uso do Enum `PropId`**: Em Python, utilize sempre `core.etiquetas_semanticas.PropId`.
3.  **Resolução de Identificadores**: Ao ler dados de fontes legadas, o sistema deve converter o ID numérico para sua etiqueta semântica imediatamente após a captura, utilizando as funções `obter_etiqueta()`.

## 3. Mapeamento de Tradução (Excerto)
| ID | Etiqueta | Significado |
| :---: | :--- | :--- |
| 7 | `editavel` | O campo pode ser alterado pelo usuário. |
| 8 | `obrigatorio` | O campo deve ser preenchido para validação. |
| 17 | `reprocessar` | Força o recalculo do campo em eventos. |
| 38 | `cascata_de_regra` | Controla a recursão de triggers. |

---
*Referência Técnica: `src/core/etiquetas_semanticas.py`*
