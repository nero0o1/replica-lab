# 05_A_Auditoria_Estrutural_e_Containers.md

## 1. Identificação dos Containers

Esta auditoria estabelece a estrutura física e lógica dos containers de dados para o Editor 2 (Legacy) e Editor 3 (Modern/Soul).

### 1.1. Comparativo de Arquivos

| Característica | Editor 2 (Legacy) | Editor 3 (Modern) |
| :--- | :--- | :--- |
| **Extensão** | `.edt` | `.edt` |
| **Formato Base** | XML (RowSet / DataPacket pattern) | JSON |
| **Encoding** | Windows-1252 / ISO-8859-1 (Implícito) | UTF-8 (Strict No BOM) |
| **Assinatura** | `<editor><item tableName='EDITOR_DOCUMENTO'...` | `{"name": "...", "data": { ... }}` |
| **Mime-Type** | `application/xml` | `application/json` |

---

## 2. Anatomia do Editor 2 (Legacy XML)

O formato legado não é apenas um XML de dados; é um **Object Graph Serializado** que reflete diretamente a estrutura de tabelas do banco de dados Oracle.

### 2.1. Estrutura Raiz
O arquivo começa com a tag `<editor>`, encapsulando itens que representam linhas de tabelas.

```xml
<editor>
  <item tableName='EDITOR_DOCUMENTO' parentRefId='CD_DOCUMENTO' type='DOC'>
    <data>
      <ROWSET>
        <ROW>
          <CD_DOCUMENTO>907</CD_DOCUMENTO>
          <DS_DOCUMENTO>CHEC_CC_ADM</DS_DOCUMENTO>
          <!-- ... -->
        </ROW>
      </ROWSET>
    </data>
    <children>
      <!-- Associações (Foreign Keys virtuais) -->
    </children>
  </item>
</editor>
```

### 2.2. O Mistério do Layout (Revelado)
A maior descoberta desta auditoria é a natureza do armazenamento de layout no Legacy. Ele **NÃO** é descritivo (como HTML ou JSON).

*   **Campo:** `LO_REL_COMPILADO`
*   **Conteúdo:** `ACED000573720028...`
*   **Análise:** O header `AC ED 00 05` confirma que se trata de uma **Java Serialized Object Stream**.
*   **Classe Java:** `net.sf.jasperreports.engine.JasperReport`
*   **Significado:** O layout legado é um binário compilado do **JasperReports**. Isso confirma que o Editor 2 era, na verdade, um designer de JasperReports disfarçado.

> [!WARNING]
> **Impossibilidade de Conversão Direta:** Não é possível "converter" textualmente o `LO_REL_COMPILADO` para o layout HTML/JSON do Editor 3. A migração exige a reconstrução total do layout visual (posicionamento X,Y), pois o binário Java é opaco para sistemas não-Java.

---

## 3. Anatomia do Editor 3 (Modern JSON)

O formato moderno adota uma abordagem "Document Store", desacoplada do banco relacional em sua estrutura física, mas mantendo os IDs como chaves de integridade.

### 3.1. Estrutura Raiz
Objeto JSON plano com containers lógicos.

```json
{
  "name": "Nome do Documento",
  "identifier": "IDENTIFICADOR_TEXTUAL",
  "data": {
    "propertyDocumentValues": [ ... ]
  },
  "version": {
    "hash": "md5_hash_string",
    "layouts": [
      {
        "content": "{\"children\":[...]}", // Inception Serialization
        "viewType": "HTML"
      }
    ]
  }
}
```

### 3.2. A Lei da Serialização "Inception"
Diferente do XML, onde a hierarquia é nativa, o JSON do Editor 3 usa uma técnica de **Dupla Serialização** para o layout.

*   O campo `layouts[0].content` **NÃO** é um objeto JSON.
*   É uma **STRING** contendo um JSON escapado.
*   **Motivo Provável:** Armazenamento como CLOB/TEXT no banco de dados, evitando a complexidade de tipos JSON nativos do Oracle/Postgres em versões antigas.

---

## 4. Mapeamento Estrutural (Rosetta Stone)

| Conceito | XML Path (Legacy) | JSON Path (Modern) | Observação |
| :--- | :--- | :--- | :--- |
| **ID Numérico** | `//CD_DOCUMENTO` | N/A (Desacoplado) | O V3 usa Identificadores textuais como chave primária lógica. |
| **Identificador** | `//DS_IDENTIFICADOR` | `$.identifier` | Chave de ligação principal. |
| **Propriedades** | `//children/item[@type='PROPRIEDADE']` | `$.data.propertyDocumentValues` | No XML é hierárquico; no JSON é lista plana. |
| **Layout** | `//LO_REL_COMPILADO` (Java Bin) | `$.version.layouts[].content` (JSON String) | Incompatibilidade total de formato. |
| **Grupos** | `//children/item[@type='GRUPO']` | `$.group` | Estrutura de pasta/hierarquia. |

## 5. Integridade e Hashing

*   **Legacy:** Confia na consistência transacional do RDBMS. O "estado" é o snapshot do banco.
*   **Modern:** Implementa integridade autonômica via `version.hash`.
    *   **Algoritmo:** `MD5(Minified(data))`
    *   **Regra de Booleanos:**
        *   `true` -> `"b326b5062b2f0e69046810717534cb09"`
        *   `false` -> `"68934a3e9455fa72420237eb05902327"`

## 6. Conclusão da Auditoria A

O "Abismo de Formato" entre V2 e V3 é profundo, especificamente na camada de **Apresentação (Layout)**.

1.  **Dados:** A migração de DADOS é possível e determinística (mapeamento de propriedades).
2.  **Visual:** A migração de LAYOUT é impossível via parse direto do `LO_REL_COMPILADO`.
3.  **Estratégia Recomendada:** O `ReplicaEditor` deve focar na geração correta da **árvore de propriedades (Canonical Model)**. O layout visual precisará ser "redesenhado" ou usar um template padrão "Auto-Form" baseado na ordem das propriedades, já que extrair coordenadas X/Y do binário JasperReports é inviável sem engenharia reversa pesada da classe Java `JasperReport`.

**Próximo Passo (Artifact 05_B):** Mapeamento detalhado dos Tipos de Propriedade (Dicionário de Dados).
# 05_B_Dicionario_Mestre_de_Propriedades

## 1. Visão Geral
Este artefato consolida o mapeamento entre os IDs numéricos do Editor Leagdo (XML/Jasper) e os identificadores textuais/estruturais do Editor Moderno (JSON).
Baseado na análise forense dos arquivos do diretório `02_campos`.

## 2. Tipos de Visualização (CD_TIPO_VISUALIZACAO)
Esta tabela define a "Pedra de Roseta" para a conversão de tipos entre V2 e V3.

| Nome de Exibição | ID V2 | ID V3 | Identificador V3 | Observação |
| :--- | :---: | :---: | :--- | :--- |
| **Texto** | 1 | 1 | `TEXT` | Campo alfanumérico padrão. |
| **Caixa de Texto** | 2 | 2 | `TEXTAREA` | Texto multi-linha. |
| **ComboBox** | 3 | 3 | `COMBOBOX` | Lista de seleção única. |
| **CheckBox** | 4 | 4 | `CHECKBOX` | Seleção binária. |
| **Marcação Imagem** | - | 5 | `IMAGEMARKER` | Exclusivo V3. |
| **Ponto de Rádio** | 7 | 6 | `RADIOBUTTON` | **SHIFT**: V2(7) -> V3(6). |
| **Botão** | 10 | 7 | `BUTTON` | **SHIFT**: V2(10) -> V3(7). |
| **Código de Barras** | - | 8 | `BARCODE` | Exclusivo V3. |
| **Data** | 11 | 9 | `DATE` | **SHIFT**: V2(11) -> V3(9). |
| **Imagem** | 12 | 10 | `IMAGE` | **SHIFT**: V2(12) -> V3(10). |
| **Texto Formatado** | - | 12 | `FORMATTEDTEXT` | Exclusivo V3. |
| **Gráfico** | - | 26 | `CHART` | Exclusivo V3. |
| **Hyperlink** | - | 28 | `HYPERLINK` | Exclusivo V3. |
| **Tabela Interativa**| - | 35 | `GRID` | Exclusivo V3. |
| **Audiometria** | - | 36 | `AUDIOMETRY` | Exclusivo V3. |

> [!NOTE]
> Para tipos "Exclusivo V3", o conversor Legado (V2) aplica um fallback para **Texto (Tipo 1)** em modo Read-Only com aviso no rótulo.

> [!CAUTION]
> **VETO DE HEURÍSTICAS NUMÉRICAS**:
> O usuário **proibiu explicitamente** a conversão automática de campos com máscara numérica (ex: `999.999.999-99`) para o tipo `Number` do JSON.
> **Motivo**: O Editor 2 trata esses dados como `VARCHAR` para preservar zeros à esquerda (ex: CPF, CEP). A conversão para `Number` destruiria essa informação (0123 -> 123).
> **Regra**: Todo campo com máscara deve ser mantido como **STRING**, exceto se o Editor 3 exigir explicitamente numérico para cálculo.

> [!WARNING]
> **Formatos de Data**:
> - **V2 (Legado)**: Utiliza formato Oracle `DD/MM/RR` ou `DD/MM/YYYY`. O Driver deve respeitar isso estritamente na escrita.
> - **V3 (Moderno)**: Utiliza formato ISO-8601 (`YYYY-MM-DD`).
> - **Ação**: O Driver de Migração deve realizar a conversão bidirecional correta. Não envie ISO para o V2!

## 3. Mapeamento de Propriedades (EDITOR_CAMPO_PROP_VAL)
Mapeamento de `CD_PROPRIEDADE` para chaves do JSON.

### Tabela Mestra de Propriedades

| ID | Nome (XML) | Chave JSON (V3) | Tipo Dados | Descrição / Observações |
|:---:|:---|:---|:---:|:---|
| **1** | Tamanho | `tamanho` | `Integer` | Comprimento máximo do campo. |
| **2** | Lista de Valores | `lista_valores` | `Array` | **GAP FIX**: Não é string, é aninhamento de tabela. |
| **3** | Máscara | `mascara` | `String` | Formatação (Ex: CPF, CEP, DATAHORA). |
| **4** | Ação | `acao` | `String` | Query SQL ou lógica de ação. |
| **5** | Usado em | `usado_em` | `String` | Metadados de dependência. |
| **7** | Editável | `editavel` | `Boolean` | Se permite edição. |
| **8** | Obrigatório | `obrigatorio` | `Boolean` | Determina se o preenchimento é compulsório. |
| **9** | Valor Inicial | `valor_inicial` | `String` | Valor padrão. |
| **10** | Criado Por | `criado_por` | `String` | Auditoria (Usuário). |
| **13** | Ação Texto Padrão | `acao_texto_padrao` | `String` | SQL para busca de texto dinâmico. |
| **14** | Texto Padrão | `texto_padrao` | `String` | Conteúdo fixo inicial. |
| **15** | Parâmetros Texto | `parametros_texto_padrao`| `String` | Interpolação no texto padrão. |
| **17** | Reprocessar | `reprocessar` | `Boolean` | Flag de trigger/refresh. |
| **19** | Tipo Barcode | `barcode_type` | `String` | Padrão (CODE_93, CODE_128, etc). |
| **20** | Exibir Label BC | `show_barcode_label` | `Boolean` | Exibir texto abaixo do código. |
| **21** | Ação SQL | `acaoSql` | `String` | **GAP FIX**: Código SQL para execução em eventos. |
| **35** | Tipo Gráfico | `tipo_do_grafico` | `String` | **GAP FIX**: Define o estilo do gráfico/grid. |
| **22** | Regras Usadas | `regras_usadas` | `String` | Vinculo com regras de negócio. |
| **23** | Voz | `voz` | `Boolean` | Reconhecimento de voz. |
| **24** | Criado Em | `criado_em` | `String` | Timestamp de criação. |
| **30** | Dica (Hint) | `hint` | `String` | Texto de ajuda/tooltip. |
| **31** | Descrição API | `descricaoApi` | `String` | Docs técnicas para integração. |
| **33** | Importado | `importado` | `Boolean` | Flag de origem. |
| **34** | Migrado | `migrado` | `Boolean` | Flag de status de migração. |
| **38** | Cascata de Regra | `cascata_de_regra` | `Boolean` | Lógica de propagação de condições. |

## 4. Estratégia de Migração (Análise de Gaps)

### O Problema da "Verdade Visual"
O Editor Leagdo mistura **Comportamento** (Lógica) com **Apresentação** (Layout) dentro da definição do campo em alguns casos, mas a maioria das propriedades visuais (X, Y, Largura, Altura) reside no **Layout** (Container), não no Campo.

**Decisão Arquitetural**:
1.  **Campos (JSON)**: Devem armazenar apenas **O QUE** é o dado (Tipo, Máscara, Obrigatoriedade, SQL).
2.  **Layout (JSON)**: Deve armazenar **ONDE** e **COMO** ele aparece.

### Tratamento de Tipos Derivados
Para suportar tipos modernos como `NUMBER`, `MONEY`, `CPF` que não existem nativamente no legado:
- **Parser**: Ao ler um Tipo 1 (Texto), verificar a propriedade **3 (Máscara)**.
- **Heurística**:
    - Se Máscara contém `#` ou `0` apenas -> Converter para `NUMBER`? **Risco**: Melhor manter como `TEXT` com `mask` no JSON para fidelidade.
    - Se Máscara == `DATAHORA` -> Manter `TEXT` com `format: "datetime"` ou migrar para componente de DataHora real (se suportado pelo motor V3).

## 5. Próximos Passos
- Validar esta estrutura com o script `RosettaStone.ps1` (atualizar se necessário).
- Utilizar este dicionário para a geração automática dos arquivos JSON de Campos na Fase 3.
