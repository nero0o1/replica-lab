# 05_F: Anatomia Comparada Integral (Mapa Forense V2/V3)

> [!IMPORTANT]
> **DOCUMENTO MESTRE DE REFERÊNCIA**: Este artefato contém a verdade nua e crua sobre as estruturas de dados.
> **MODO ESPELHO ATIVO**: O objetivo é a reprodução fidelíssima, incluindo redundâncias e idiossincrasias do legado.

## 1. Estrutura de Arquivo (File Structure)

### V2: Legado (XML)
O arquivo `.edt` é um XML sem declaração `<?xml ...?>` na primeira linha em alguns casos (verificar driver), mas com a raiz `<editor>`.

| Elemento | Caminho / Tag | Obrigatório? | Comportamento/Valor |
| :--- | :--- | :--- | :--- |
| **Raiz** | `<editor>` | SIM | Container global. |
| **Documento** | `<item tableName='EDITOR_DOCUMENTO' parentRefId='CD_DOCUMENTO' type='DOC'>` | SIM | Define o contexto do documento. |
| **Metadados (Data)** | `.../data/ROWSET/ROW` | SIM | Contém `CD_DOCUMENTO`, `DS_DOCUMENTO`. |
| **Versão** | `.../children/association[@childTableName='EDITOR_VERSAO_DOCUMENTO']/item` | SIM | A versão é filha do documento. |
| **Campos (Link)** | `.../children/association[@childTableName='EDITOR_LAYOUT_CAMPO']` | SIM | Dentro da Versão. Liga Documento -> Layout -> Campo. |
| **Hierarquia** | `<hierarchy><group name='...' type='G_CAM'>` | SIM | No final do arquivo, fora do `item` principal. Define pastas. |

**Exemplo de Cabeçalho V2:**
```xml
<editor>
  <item tableName='EDITOR_DOCUMENTO' parentRefId='CD_DOCUMENTO' type='DOC'>
    <data><ROWSET><ROW>...</ROW></ROWSET></data>
...
```

### V3: Moderno (JSON)
O arquivo `.edt` é um JSON puro, geralmente minificado na exportação final, mas formatado no desenvolvimento.

| Chave | Tipo | Obrigatório? | Comportamento/Valor |
| :--- | :--- | :--- | :--- |
| **`identifier`** | String | SIM | ID único textual (Ex: `CHEC_CC_ADM`). |
| **`versionStatus`** | String | SIM | `PUBLISHED` ou `DRAFT`. |
| **`data`** | Objeto | SIM | Contém o ID numérico antigo (`id`). |
| **`fields`** | Array | SIM | Lista plana de definições de campos. |
| **`groups`** | Array | SIM | Define a hierarquia visual (layout) e contém referências aos campos. |
| **`version`** | Number | SIM | Número sequencial da versão. |

**Exemplo de Cabeçalho V3:**
```json
{
  "name": "CHEC_CC_ADM",
  "identifier": "CHEC_CC_ADM",
  "versionStatus": "PUBLISHED",
  "data": { "id": 907 },
  ...
}
```

---

## 2. Propriedades dos Campos: A Pedra de Roseta Expandida

Mapeamento rigoroso de `CD_PROPRIEDADE` (V2) para `identifier` (V3) e seus tipos de dados.

| ID (V2) | Nome (V2) | Tag XML V2 | V3 JSON Key | Tipo V2 (XML) | Tipo V3 (JSON) | Conversão Crítica |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | Tamanho | `<LO_VALOR>X</LO_VALOR>` | `tamanho` | String/Int | Integer | `Int.Parse(val)` |
| **2** | Lista Valores | *(Complexo - N linhas)* | `lista_valores` | Rows em `EDITOR_PROPRIEDADE` | Array of Strings | Ver nota abaixo (*). |
| **3** | Máscara | `<LO_VALOR>M</LO_VALOR>` | `mascara` | String | String | Direto. |
| **4** | Ação (SQL) | `<LO_VALOR>SQL</LO_VALOR>` | `acao` | String (SQL Bruto) | String | Preservar quebras de linha em V2? V3 escapa `\n`. |
| **5** | Usado Em | `<LO_VALOR>X</LO_VALOR>` | `usado_em` | String | String | Informativo. |
| **7** | Editável | `<LO_VALOR>S</LO_VALOR>` ou `true` | `editavel` | String (`S`/`N`/`true`/`false`) | Boolean | `val == 'S' || val == 'true'` |
| **8** | Obrigatório | `<LO_VALOR>S</LO_VALOR>` ou `true` | `obrigatorio` | String (`S`/`N`/`true`/`false`) | Boolean | `val == 'S' || val == 'true'` |
| **9** | Valor Inicial | `<LO_VALOR>V</LO_VALOR>` | `valor_inicial` | String | String | Direto. |
| **10** | Criado Por | `<LO_VALOR>U</LO_VALOR>` | `criado_por` | String | String | Direto. |
| **17** | Reprocessar | `<LO_VALOR>S</LO_VALOR>` | `reprocessar` | String (`S`/`N`) | Boolean | `val == 'S'` |
| **21** | Ação SQL | `<LO_VALOR>SQL</LO_VALOR>` | `acaoSql` | String (SQL) | String | **GAP FIX**: Código SQL puro. |
| **35** | Tipo Gráfico | `<LO_VALOR>G</LO_VALOR>` | `tipo_do_grafico` | String | String | **GAP FIX**: Estilo do gráfico/grid. |

> **(*) Lista de Valores (ID 2)**:
> - **V2**: É uma tabela filha aninhada! `<children><association childTableName='EDITOR_PROPRIEDADE'><item...><DS_IDENTIFICADOR>Valor1</DS_IDENTIFICADOR>`.
> - **V3**: É um array simples: `["Valor1", "Valor2"]`.
> - **Ação**: O conversor deve "explodir" o array V3 em múltiplas linhas `<item>` no XML V2.

### Tabela de Tipos Visuais (CD_TIPO_VISUALIZACAO)

| V2 ID | Nome V2 | V3 ID | V3 Identifier | Notas de "Bug Compatibility" |
| :--- | :--- | :--- | :--- | :--- |
| **1** | Texto | **1** | `TEXT` | Padrão. |
| **2** | Área Texto | **2** | `TEXTAREA` | Padrão. |
| **3** | ComboBox | **3** | `COMBOBOX` | V2 exige `lista_valores` preenchida ou `acao` SQL. |
| **4** | CheckBox | **4** | `CHECKBOX` | Nativo no V2. |
| **N/A** | Marcação Imagem | **5** | `IMAGEMARKER` | Exclusivo V3. |
| **7** | Radio | **6** | `RADIOBUTTON` | **ID SHIFT**: V2(7) -> V3(6). |
| **10** | Botão | **7** | `BUTTON` | **ID SHIFT**: V2(10) -> V3(7). |
| **N/A** | Código Barras | **8** | `BARCODE` | Exclusivo V3. |
| **11** | Data | **9** | `DATE` | **ID SHIFT**: V2(11) -> V3(9). Formato `DD/MM/RR` vs `YYYY-MM-DD`. |
| **12** | Imagem | **10** | `IMAGE` | **ID SHIFT**: V2(12) -> V3(10). |
| **N/A** | Texto Formatado| **12** | `FORMATTEDTEXT` | Exclusivo V3. |
| **N/A** | Gráfico | **26** | `CHART` | Exclusivo V3. |
| **N/A** | Hyperlink | **28** | `HYPERLINK` | Exclusivo V3. |
| **N/A** | Tabela Interat. | **35** | `GRID` | Exclusivo V3. |
| **N/A** | Audiometria | **36** | `AUDIOMETRY` | Exclusivo V3. |

---

## 3. Relatório de Fidelidade e Falhas ("Bug Compatibility")

Para garantir que o arquivo gerado funcione no importador legado, devemos replicar os seguintes comportamentos:

### 3.1 Redundâncias Obrigatórias do V2
1.  **Repetição de `CD_CAMPO`**: Dentro de `EDITOR_CAMPO_PROP_VAL`, a coluna `CD_CAMPO` se repete em TODAS as linhas de propriedade, mesmo estando aninhada dentro do pai `EDITOR_CAMPO`. O XML gerado **DEVE** incluir essa tag `<CD_CAMPO>...</CD_CAMPO>` em cada item filho.
2.  **Repetição de `CD_TIPO_VISUALIZACAO`**: Curiosamente, a tabela de valores de propriedades também repete o `CD_TIPO_VISUALIZACAO`. Se o pai é Texto (1), as propriedades filhas também dizem que são do tipo 1.
    *   **Risco**: Arquivos V2 sujos às vezes tem propriedades "órfãs" com tipos errados (ex: pai é Texto, mas tem uma propriedade de Checkbox perdida).
    *   **Decisão**: O exportador deve limpar isso e escrever apenas propriedades pertinentes ao tipo atual, mas deve preencher a coluna `CD_TIPO_VISUALIZACAO` corretamente nas filhas.

### 3.2 Formatação de Strings
1.  **SQL (Ação)**:
    *   **V2**: Aceita quebras de linha reais no XML (`&#10;` ou literais).
    *   **V3**: Geralmente minifica ou escapa `\n`.
    *   **Conversão**: Ao voltar para V2, devemos "desescapar" para garantir legibilidade no editor Delphi antigo, ou garantir que o parser XML aceite `\n`.

2.  **Booleanos Híbridos**:
    *   O Editor 2 é inconsistente. Alguns campos usam `S/N`, outros (vindois de versões mais novas do legado) usam `true/false` (texto).
    *   **Estratégia**: O Driver V2 deve ter uma tabela de lookup: "Propriedade 8 (Obrigatório) -> Escrever 'S' ou 'false'?".
    *   *Análise preliminar indica `false` (minúsculo) e `true` presentes em XMLs recentes para propriedades como `obrigatorio` e `editavel`, mas `S` para `SN_ATIVO`.*

---

## 4. Incompatibilidades Irreconciliáveis

### 4.1 Exclusivo V3 -> Perda em V2
1.  **Grids e Charts**: Não existem no V2.
    *   *Fallback*: Converter para um campo Texto (ReadOnly) com um aviso "Componente [Grid] não suportado no legado".
2.  **Hashes de Segurança**: O V2 ignora. Podemos descartar na exportação V2.
3.  **Layout Responsivo (Colspan complexo)**: O V2 usa um grid rígido. Layouts complexos do V3 podem ficar desajeitados no V2.

### 4.2 Exclusivo V2 -> Perda em V3
1.  **Links diretos de Tabela (`EDITOR_table_name`)**: O V3 abstrai tudo para o objeto Documento/Campo. Referências cruzadas esotéricas podem se perder se não houver um campo correspondente no JSON.

---

## 5. Bloqueios de Integridade e Serialização (GAP FIX)

### 5.1 O "Cabeçalho Fantasma" (Java Object)
O arquivo `.edt` V2 **NÃO É XML PURO**. É um objeto Java Serializado.
- **Assinatura**: Inicia com **`ACED0005`** (Java Serialization Magic Number).
- **Risco**: Se você tentar dar `Parse` no arquivo bruto como XML, o parser falhará no primeiro byte.
- **Regra**: O Importer deve realizar um "Binary Scrubbing" para localizar as tags `<editor>` e extrair o conteúdo XML do meio dos bytes serializados. O Driver deve ter a capacidade de re-encapsular (ou mocar) este cabeçalho.

### 5.2 Regra da "Matrioska" (Dupla Serialização)
No Editor 3 (JSON), o nó `layouts.content` **não é um objeto JSON direto**.
- **Realidade (Fonte 537)**: É uma **STING** que contém um JSON stringificado.
- **Por que?**: O parser do MV executa `JSON.parse()` no arquivo e depois chama `JSON.parse()` novamente apenas no campo `content`. Se já for um objeto, o segundo parse falha (Erro de Tipo).

### 5.3 Tabela de Hashes Obrigatórios (Forense)
Para passar na validação do Editor 3, as propriedades básicas EXIGEM estes hashes MD5:
| Valor | Tipo | Hash MD5 (Obrigatório) |
| :--- | :--- | :--- |
| `true` | Boolean String | `b326b5062b2f0e69046810717534cb09` |
| `false` | Boolean String | `68934a3e9455fa72420237eb05902327` |
| `0` | Integer | `cfcd208495d565ef66e7dff9f98764da` |

---

## 6. Estratégia de Implementação (Dual-Driver Architecture)

Para suportar essa "esquizofrenia" de formatos, a arquitetura deve ser:

1.  **Modelo Interno (Superset)**: Uma classe C#/TS/PS que contém *todas* as propriedades possíveis de ambos.
    *   `IdLegacy` (int)
    *   `Identifier` (string)
    *   `Properties` (Dictionary<string, object>) - Armazena tudo.

2.  **Driver V2 (Conversor Legacy)**:
    *   **Input**: Modelo Interno.
    *   **Output**: XML (`StringBuilder` ou `XmlDocument`).
    *   **Responsabilidade**: Injetar redundâncias (`CD_CAMPO` repetido), formatar datas `DD/MM/RR`, converter bool para `S/N`/`true`/`false` conforme a regra da propriedade específica.

3.  **Driver V3 (Conversor Modern)**:
    *   **Input**: Modelo Interno.
    *   **Output**: JSON.
    *   **Responsabilidade**: Gerar estrutura limpa, arrays `fieldPropertyValues`, datas ISO-8601, calcular Hash de versão.

Esta separação blindará a lógica de negócio das loucuras de formatação de cada versão.
