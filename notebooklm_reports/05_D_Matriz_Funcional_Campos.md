# 05_D_Matriz_Funcional_Campos

Este documento responde à necessidade de **identificar corretamente** os tipos de campos, suas disponibilidades e capacidades em cada versão do Editor.

## 1. Visão Geral de Capacidades

| Característica | Editor 2 (Legado) | Editor 3 (Moderno) |
| :--- | :--- | :--- |
| **Foco** | Entrada de Dados Tradicional (Formulário) | Elementos Ricos e Interativos (Aplicação) |
| **Tipos Básicos** | Texto, Combo, Radio, Data, Imagem | Todos do V2 + Checkbox Nativo |
| **Tipos Avançados** | Não Suportado | Gráficos, Grids, Barcodes, Hiperlinks |
| **Layout** | Posicional (X,Y fixos ou fluxo simples) | Flexível (Groups, Containers) |

---

## 2. Matriz de Tipos de Campo (O "Catálogo")

A tabela abaixo cruza os IDs para garantir a tradução correta e lista as capacidades exclusivas.

| Nome do Componente | V2 ID | V3 ID | V3 Identifier | Capacidades / Opções Principais |
| :--- | :---: | :---: | :--- | :--- |
| **Texto Simples** | 1 | 1 | `TEXT` | Máscaras, Tamanho, Valor Inicial. |
| **Texto Multilinha** | 2 | 2 | `TEXTAREA` | Caixa de Texto, Memo. |
| **Combo Box** | 3 | 3 | `COMBOBOX` | Lista de Seleção Única (`lista_valores`). |
| **CheckBox** | 4 | 4 | `CHECKBOX` | Seleção binária nativa. |
| **Marcação Imagem** | - | 5 | `IMAGEMARKER` | Seleção em imagem de fundo. |
| **Radio Button** | 7 | 6 | `RADIOBUTTON` | **SHIFT**: V2(7) -> V3(6). |
| **Botão** | 10 | 7 | `BUTTON` | **SHIFT**: V2(10) -> V3(7). Ações. |
| **Código de Barras** | - | 8 | `BARCODE` | Tipo (Code 93, 128), Label. |
| **Data** | 11 | 9 | `DATE` | **SHIFT**: V2(11) -> V3(9). Datepicker. |
| **Imagem** | 12 | 10 | `IMAGE` | **SHIFT**: V2(12) -> V3(10). Base64. |
| **Texto Formatado** | - | 12 | `FORMATTEDTEXT`| Máscara "NUMBER", moedas. |
| **Gráfico (Chart)** | - | 26 | `CHART` | Bar, Pie, Line. Min/Max. |
| **Hiperlink** | - | 28 | `HYPERLINK` | Links externos/âncoras. |
| **Tabela (Grid)** | - | 35 | `GRID` | Multirecord interativo, API data. |
| **Audiometria** | - | 36 | `AUDIOMETRY` | Exame de audição especializado. |

> [!WARNING]
> **Colisão de IDs Crítica**:
> *   O ID **7** era *Radio Button* (V2) e virou *Botão* (V3).
> *   O ID **12** era *Imagem* (V2) e virou *Texto Formatado* (V3).
> *   **Conclusão**: Jamais copie IDs crus da V2 para V3. Use a tabela de tradução do `RosettaStone`.

---

## 3. Detalhes dos Tipos Exclusivos (Modern Editor 3)

### 📊 Gráfico (Chart) - ID 26
Permite criar dashboards dentro do documento.
*   **Opções Chave**:
    *   `tipo_do_grafico`: BAR, PIE, LINE.
    *   `min_do_grafico` / `max_do_grafico`: Escala dos eixos.
    *   `cascata_de_regra`: Gatilhos condicionais.

### 🔳 Grid (Tabela Interativa) - ID 35
Substitui o antigo conceito de "Bloco Multirecord" rígido.
*   **Capacidade**: Renderiza coleções de dados dinâmicos.
*   **Integração**: Pode ser populado via `requisicao_api`.

### 🏷️ Barcode - ID 8
Geração automática de etiquetas.
*   **Opções**:
    *   `barcode_type`: Define o padrão (ex: CODE_93).
    *   `show_barcode_label`: Exibe ou oculta o texto legível humanamente.

---

## 4. Como Adicionar aos Documentos?

No Editor 3, campos não são apenas posicionados; eles são **Agrupados**.
*   **Estrutura**: Todo campo pertence a um `group` (ex: `G_CAM`, ID 6).
*   **Hierarquia**: O JSON do campo contém metadados do seu grupo pai.
    ```json
    "group" : { "id" : 2342, "identifier" : "G_CAM" ... }
    ```
*   **Análise Futura**: A estrutura exata de como esses grupos compõem o layout visual será detalhada no artefato `05_E_Sintaxe_de_Layouts_e_Componentes.md`.
