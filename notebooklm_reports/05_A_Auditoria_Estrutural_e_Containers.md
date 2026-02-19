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
