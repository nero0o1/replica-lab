# FRONTEND REACT MAPPING - Dicionário de Componentes e Estilização

## 1. Mapeamento de Componentes (AST -> React)
| Componente MV | Tipo V3 | Comportamento Reativo |
| :--- | :--- | :--- |
| **TEXT** | 1 | Input alfanumérico com suporte a máscaras de entrada (ID 3). |
| **LABEL** | 2 | Span estático consumindo `texto_padrao` (ID 14). |
| **COMBOBOX** | 3 | Select pesquisável consumindo `lista_valores` tokenizada. |
| **RADIOBUTTON**| 4 | Grupo mutuamente exclusivo. |
| **CHECKBOX** | 5 | Input binário persistido como 'S'/'N'. |
| **IMAGE** | 10| Renderizador de Base64 com preservação de metadados binários. |
| **DYNAMIC-TABLE**| 12| Grids repetíveis com suporte a adição/remoção em tempo real. |

## 2. Design Tokens e Paridade Visual
- **Tipografia**: Mapear fontes legadas (Arial, Tahoma, MS Sans Serif) para stacks CSS equivalentes.
- **Cores**: Conversão rigorosa de Windows (BGR Decimal) para CSS Hex. Aplicar heurística de contraste se `color` for omitida.
- **Bordas**: Traduzir relevos legados (Flat/3D) para `box-shadow` e `border`.

## 3. Geometria e Ancoragem
- **Bounding Box**: O motor de renderização deve respeitar as dimensões absolutas da AST.
- **Mobile Geometry**: Proibido aplicar heurísticas de escala (Zoom-out) automática. O comportamento mandatório é **forçar o scroll horizontal** (Modo Desktop em tela pequena), garantindo a fidelidade posicional absoluta.
- **Z-Index Matrix**: Utilizar a matriz de profundidade capturada para sobreposição correta de elementos clínicos.

## 4. UI de Quarentena e Segurança
- **Inert Components**: Campos marcados como quarentena devem exibir o aviso: *"Automated Logic Transfer Quarantined: This field depends on complex PL/SQL..."*.
- **Alert Style**:
    - Border-left: `4px solid #f39c12`
    - Background: `rgba(243, 156, 18, 0.05)`
