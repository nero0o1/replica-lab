# 05_C_Identidade_e_Diferencas_Campos

Este documento define a **Identidade Estrutural** dos campos para os Editores V2 (Legado) e V3 (Moderno), estabelecendo critérios claros para diferenciação e identificação automática.

## 1. A "Impressão Digital" (Fingerprint)

A distinção primária é o **Formato de Serialização**.

| Característica | Editor 2 (V2 / Legado) | Editor 3 (V3 / Moderno) |
| :--- | :--- | :--- |
| **Formato** | **XML** (Proprietário) | **JSON** (Padrão) |
| **Assinatura (Start)** | `<editor>` ou `<registro>` | `{` (Objeto JSON) |
| **Extensão** | `.edt` (Texto/XML) | `.edt` (Texto/JSON) |
| **Estrutura Raiz** | Tabela `EDITOR_CAMPO` | Objeto `data` com `itemType` |

### Lógica de Detecção (PowerShell)
```powershell
function Get-EditorVersion {
    param([string]$Content)
    
    $clean = $Content.Trim()
    if ($clean.StartsWith("<")) { return "V2_XML" }
    if ($clean.StartsWith("{")) { return "V3_JSON" }
    return "UNKNOWN"
}
```

---

## 2. Anatomia do Campo

### Editor 2 (XML / V2)
Baseado em **Tabelas Relacionais** serializadas em XML.
*   **Identificador**: `CD_CAMPO` (Numérico) e `DS_CAMPO` (Nome interno).
*   **Tipo Visual**: `CD_TIPO_VISUALIZACAO` (ID Numérico Legado: 1, 2, 3, 7, 11, 12).
*   **Propriedades**: Armazenadas como registros filhos na tag `<children><association childTableName='EDITOR_CAMPO_PROP_VAL'>`.
    *   Exemplo: `<item ... type='EDITOR_CAMPO_PROP_VAL'><data>...<CD_PROPRIEDADE>2</CD_PROPRIEDADE>...</data>`

### Editor 3 (JSON / V3)
Baseado em **Objetos e Grafos** serializados em JSON.
*   **Identificador**: `id` (Numérico) e `identifier` (String única, ex: `CAMPO_DE_TEXTO`).
*   **Tipo Visual**: Objeto `visualizationType` com `id` (ID Moderno: 1, 2, 3, 4, 6, 9, 10).
*   **Propriedades**: Array `fieldPropertyValues` dentro do objeto raiz.
    *   Exemplo: `"fieldPropertyValues" : [ { "property" : { "id" : 2 ... }, "value" : "..." } ]`

---

## 3. Mapeamento de Identidade (Cross-Identity)

A migração exige a tradução de identidades, pois os **IDs Numéricos de Tipo mudaram**.

| Conceito | V2 (XML) Tag | V3 (JSON) Key | Notas de Migração |
| :--- | :--- | :--- | :--- |
| **Nome** | `<DS_CAMPO>` | `identifier` | Manter valor exato. |
| **Tipo Visual** | `<CD_TIPO_VISUALIZACAO>` | `visualizationType.id` | **Traduzir**: 7->6, 11->9, 12->10. |
| **Propriedade Chave** | `<CD_PROPRIEDADE>` | `fieldPropertyValues[].property.id` | IDs 1:1, exceto conflito ID 17. |
| **Valor Propriedade** | `<LO_VALOR>` | `fieldPropertyValues[].value` | Strings literais vs Booleanos strings ("true"). |

## 4. Resumo Executivo para Drivers

*   **Driver V2 (Leitura)**: Deve parsear XML, iterar sobre `children/association` para 'explodir' as propriedades em um objeto plano.
*   **Driver V3 (Escrita)**: Deve construir o JSON aninhado, garantindo que o `visualizationType` use o ID Moderno e as propriedades estejam no array `fieldPropertyValues`.
*   **Validação**: Um arquivo `.edt` V3 **NÃO PODE** conter tags XML. Um arquivo `.edt` V2 **NÃO PODE** ser um objeto JSON.

---
> **Conclusão:** Um campo V2 é um registro de banco de dados exportado em XML. Um campo V3 é um objeto de domínio serializado em JSON. A conversão requer reestruturação profunda, não apenas troca de extensão.
