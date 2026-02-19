# 05_E: Anatomia Detalhada de Documentos, Layouts e Componentes

> [!IMPORTANT]
> Este documento atende à solicitação de uma **anatomia muito clara e detalhada** das estruturas de dados. Ele serve como referência definitiva para engenharia reversa e migração.

## 1. Visão Geral da Estrutura (Anatomia Comparada)

A diferença fundamental entre as versões é que o **Legado (V2)** é **Relacional Hierárquico (XML)**, enquanto o **Moderno (V3)** é **Orientado a Objetos/Documento (JSON)**.

### 1.1 O "Esqueleto" do Documento

| Característica | Legado (V2 - XML) | Moderno (V3 - JSON) |
| :--- | :--- | :--- |
| **Container Principal** | `<editor>` contendo tabelas (`<item tableName='...'>`) | Objeto raiz `{}` contendo metadados e arrays |
| **Identificação** | `EDITOR_DOCUMENTO` (ID, Nome, Tipo) | `name`, `identifier`, `data.id` |
| **Conteúdo** | Aninhado em `<children><association>` | Arrays explícitos: `pages`, `fields`, `groups` |
| **Vínculo de Campos** | Relacional: `EDITOR_LAYOUT_CAMPO` liga Documento <-> Campo | Direto: Campos listados em `fields` e referenciados em `groups` |

---

## 2. Anatomia do Documento (Document Definition)

### 2.1 Legado (V2) - XML Structure
O arquivo `.edt` (na verdade XML) segue um padrão estrito de tabelas aninhadas.

```xml
<editor>
  <!-- 1. Cabeçalho do Documento -->
  <item tableName='EDITOR_DOCUMENTO' parentRefId='CD_DOCUMENTO' type='DOC'>
    <data>
      <ROWSET>
        <ROW>
          <CD_DOCUMENTO>907</CD_DOCUMENTO>
          <DS_DOCUMENTO>CHEC_CC_ADM</DS_DOCUMENTO>
          <CD_TIPO_ITEM>13</CD_TIPO_ITEM> <!-- 13 = Documento -->
        </ROW>
      </ROWSET>
    </data>
    
    <children>
      <!-- 2. Versão do Documento (Filho direto) -->
      <association childTableName='EDITOR_VERSAO_DOCUMENTO' childRefId='CD_DOCUMENTO'>
        <item tableName='EDITOR_VERSAO_DOCUMENTO' ...>
           <data><ROW>
             <VL_VERSAO>17</VL_VERSAO>
             <SN_ATIVO>S</SN_ATIVO>
           </ROW></data>
           
           <children>
             <!-- 3. Layouts e Associações de Campos (Filhos da Versão) -->
             <association childTableName='EDITOR_LAYOUT_CAMPO' ...>
               ... (Lista de Vínculos Campo <-> Layout)
             </association>
           </children>
        </item>
      </association>
    </children>
  </item>
  
  <!-- 4. Grupos/Pastas (Hierarquia Visual no Editor) -->
  <hierarchy>
    <group name='Administrador' type='G_CAM'></group>
  </hierarchy>
</editor>
```

### 2.2 Moderno (V3) - JSON Structure
O arquivo `.edt` (agora JSON) é linear e focado na estrutura de renderização.

```json
{
  "name": "CHEC_CC_ADM",
  "identifier": "CHEC_CC_ADM",
  "versionStatus": "PUBLISHED",
  "data": {
    "id": 907,
    "active": true
  },
  "pages": [ ... ],       // Definição visual das páginas
  "fields": [ ... ],      // Lista plana de TODOS os campos usados
  "groups": [ ... ],      // Agrupadores lógicos (seções)
  "version": 17
}
```

---

## 3. Anatomia do Campo (Field Definition)

Aqui reside a maior complexidade de tradução.

### 3.1 Legado (V2): O Modelo "Entidade-Atributo-Valor"
No V2, um campo **não possui propriedades fixas** no XML principal. Ele possui uma lista de *valores de propriedade* associados dinamicamente.

**Estrutura Crítica:**
1.  **`EDITOR_CAMPO`**: Define a identidade (ID, Nome, Tipo Visualização *Padrão*).
2.  **`EDITOR_CAMPO_PROP_VAL`**: Tabela filha que contém as propriedades.
    *   **Curiosidade Importante:** Um mesmo campo pode ter propriedades definidas para *tipos diferentes* (ex: propriedades de Texto E propriedades de Checkbox), resquício de edições passadas. O que vale é o `CD_TIPO_VISUALIZACAO` definido na tabela pai `EDITOR_CAMPO`.

```xml
<!-- A Identidade -->
<ROW>
  <CD_CAMPO>250030</CD_CAMPO>
  <DS_CAMPO>Logo SUS</DS_CAMPO>
  <CD_TIPO_VISUALIZACAO>12</CD_TIPO_VISUALIZACAO> <!-- 12 = Imagem -->
</ROW>

<!-- As Propriedades (Children) -->
<item tableName='EDITOR_CAMPO_PROP_VAL' ...>
  <ROW>
    <CD_PROPRIEDADE>1</CD_PROPRIEDADE> <!-- 1 = Tamanho -->
    <LO_VALOR>30</LO_VALOR>
  </ROW>
</item>
<item tableName='EDITOR_CAMPO_PROP_VAL' ...>
  <ROW>
    <CD_PROPRIEDADE>8</CD_PROPRIEDADE> <!-- 8 = Obrigatório -->
    <LO_VALOR>false</LO_VALOR>
  </ROW>
</item>
```

### 3.2 Moderno (V3): Objeto Tipado
No V3, o campo é um objeto autocontido com um array de propriedades (`fieldPropertyValues`).

```json
{
  "name": "Logo SUS",
  "identifier": "IMAGE_LOGO_SUS",
  "visualizationType": {
    "id": 10,  // 10 = IMAGE (Mapeado de 12)
    "identifier": "IMAGE"
  },
  "fieldPropertyValues": [
    { "property": { "identifier": "tamanho" }, "value": 30 },
    { "property": { "identifier": "obrigatorio" }, "value": false }
  ]
}
```

---

## 4. Anatomia de Layouts e Grupos (Containers)

Como os campos são organizados na tela?

### 4.1 Estrutura V2 (`G_CAM` e Tabelas de Layout)
No V2, a posição visual é definida pela tabela `EDITOR_LAYOUT_CAMPO`.
*   **`NR_LINHA`**: Linha na grade.
*   **`NR_COLUNA`**: Coluna na grade.
*   **`NR_COLSPAN`**: Largura (quantas colunas ocupa).

Existe também a tag `<hierarchy>` no final do arquivo XML, que define pastas lógicas (não visuais no form final, mas organizacionais no editor):
*   **`G_CAM`**: Grupo de Campos (Formulário padrão).
*   **`G_CAB_ROD`**: Grupo de Cabeçalho/Rodapé (Componente reutilizável).

### 4.2 Estrutura V3 (`groups` e `rows`)
O V3 usa um sistema de Grid System (linhas e colunas) aninhado dentro de `groups`.

```json
"groups": [
  {
    "name": "Dados do Paciente",
    "children": [  // Campos ou subgrupos
       { "fieldId": "TXT_NOME", "col": 0, "row": 0, "colspan": 6 },
       { "fieldId": "TXT_IDADE", "col": 6, "row": 0, "colspan": 2 }
    ]
  }
],
"layouts": [
  {
    "name": "Design Padrão",
    "content": "{\"pageBody\": { ... }}" // CRITICAL: Stringified JSON, not object!
  }
]
```

## 5. Anatomia de Componentes (Cabeçalhos e Rodapés)

### 5.1 Legado (V2)
São arquivos separados ou seções dentro de um arquivo marcadas com `type='G_CAB_ROD'`.
Eles funcionam exatamente como documentos, mas são importados por referência.

### 5.2 Moderno (V3)
São tratados como **Documentos Parciais**.
Muitas vezes, na migração, um cabeçalho V2 vira um "Snippet" ou um documento incluído via referência no V3.

---

### 5.3 O Bloqueio Binário: ACED0005
Diferente do XML limpo, campos como `<LO_REL_COMPILADO>` no V2 guardam objetos JasperReports serializados.
- **Assinatura**: Começam com `ACED0005` em formato Hex.
- **Tratamento**: Devem ser preservados como Hexadecimal. Tentar "limpar" esse XML quebra o importador legado.

---

## 6. Regra de Ouro: A Matrioska (Double Serialization)

No Editor 3, o campo `layouts.content` é o que chamamos de **Matrioska**.
1. Você gera o JSON do layout (com `pageBody`, `styles`, etc).
2. Você converte esse JSON em uma **STRING Escapada**.
3. Você insere essa string no campo `content` do JSON principal.
4. O sistema faz `JSON.parse()` duas vezes. Se o campo for um objeto JSON direto, o segundo parse falha e o formulário não abre.

---

> [!TIP]
> **Ponto Chave para Migração:**
> Ao ler um XML V2, ignore as propriedades em `EDITOR_CAMPO_PROP_VAL` cujo `CD_TIPO_VISUALIZACAO` não coincida com o `CD_TIPO_VISUALIZACAO` da tabela pai `EDITOR_CAMPO`. O V2 guarda "sujeira" de trocas de tipo, o V3 exige limpeza.
