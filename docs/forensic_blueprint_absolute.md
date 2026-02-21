# RELATÓRIO FORENSE ABSOLUTO: ECOSSISTEMA MV SOUL PEP (EDITOR 2/3)
**Status**: Homologado (VT-3 Audit)
**Arquitetura**: Forense de Dados & Reversão de Artefatos
**Data**: Fevereiro 2026

---

## 1. Anatomia do Artefato .edt (Serialização)

### 1.1. Estrutura de Cabeçalho e Integridade
O artefato moderno (.edt) é um container JSON plano que implementa o **Autonomous Integrity Protocol**.
- **documentName**: Nome amigável do formulário.
- **identifier**: Chave alfanumérica persistente (NM_IDENTIFICADOR).
- **version.hash**: MD5 de alta colisão calculado sobre a estrutura `minified(data)`.
    - **Algoritmo**: `MD5`
    - **Rigidez**: O hash valida campos, propriedades e ordem de layouts. Alterações manuais no JSON sem recalculação invalidam o carregamento no kernel do Soul MV.

### 1.2. O Campo Content (Inception Serialization)
O motor Editor 3 utiliza a técnica de **Double Serialization** para o layout visual.
- **Caminho**: `$.version.layouts[].content`
- **Anatomia**: O conteúdo não é um objeto JSON direto, mas uma **String Escapada** contendo a estrutura `pageBody -> children -> components`.
- **Racional**: Garante compatibilidade com o armazenamento em colunas `CLOB` no Oracle sem exigir suporte nativo a tipos JSON do RDBMS.

### 1.3. Protocolo de Escrita Forense
- **Line Endings**: O motor Editor 2 exige `\r\n` (CRLF) para sanitização de áreas de texto. O Editor 3 utiliza `\n` nativo do JSON.
- **SQL Sanitization**: Aspas simples (`'`) dentro de gatilhos SQL (Propriedade 4/21) devem ser escapadas como `&apos;` em XML ou mantidas literais em JSON, sob risco de quebra da query de execução do SmartDB.
- **Escape Path**: Caracteres `<`, `>`, `&` em blocos PL/SQL **DEVEM** usar Entity Escaping (`&lt;`, `&gt;`, `&amp;`). O uso de `CDATA` é desencorajado por quebrar parsers SAX legados.

---

## 2. Dicionário Atômico de Propriedades (IDs 1 a 43)

| ID | Identificador JSON | Tipo Primitivo | Regra de Negócio Clínica (Intent) |
| :--- | :--- | :--- | :--- |
| **1** | `tamanho` | Integer | Limite físico de caracteres no Oracle VARCHAR. |
| **2** | `lista_valores` | Array | Domínio discreto (ComboBox/Radio). |
| **3** | `mascara` | String | Formatação de dados sensíveis (CEP, CPF, DATA). |
| **4** | `acao` | Script (SQL) | Gatilho imediato de execução no DB (Trigger). |
| **5** | `usado_em` | String | Metadado de dependência estrutural. |
| **7** | `editavel` | Boolean (S/N) | Runtime Lock para segurança de dados (H1-H12). |
| **8** | `obrigatorio` | Boolean (S/N) | Constraint de preenchimento (Crucial para auditoria). |
| **9** | `valor_inicial` | String | Estado default (Preservar whitespace `' '`). |
| **10** | `criado_por` | String | Auditoria de autoria do artefato. |
| **11** | `tipo_data` | Date/Format | Especialização de campos temporais. |
| **12** | `tipo_imagem` | Blob Ref | Referência a repositório de binários. |
| **13** | `acao_texto_padrao`| SQL | Texto dinâmico baseado em contexto clínico. |
| **14** | `texto_padrao` | String | Protótipo de rótulo ou conteúdo fixo. |
| **15** | `parametros_texto` | String | Interpolação de variáveis de sessão. |
| **17** | `reprocessar` | Boolean | Refresh forçado do componente em dependências. |
| **19** | `barcode_type` | String | Definição de simbologia (Standard 1D/2D). |
| **20** | `show_barcode` | Boolean | Visibilidade do label humano sob o código. |
| **21** | `acao_sql` | Script (SQL) | Lógica reativa em eventos de clique/alteração. |
| **22** | `regras_usadas` | Composite | Hub de condições lógicas (RuleLexer). |
| **23** | `voz` | Boolean | Habilita captura por SR (Speech Recognition). |
| **24** | `criado_em` | Timestamp | Data de nascimento do registro. |
| **30** | `hint` | String | Tooltip/Ajuda contextual (Acessibilidade). |
| **31** | `descricao_api` | String | Endpoint/Key para integrações de terceiros. |
| **33** | `importado` | Boolean | Sinaliza origem externa do metadado. |
| **34** | `migrado` | Boolean | Status de transição legado -> moderno. |
| **38** | `cascata_regra` | Boolean | **CRÍTICO**: Previne loops infinitos na UI. |
| **41** | `max_grafico` | Number | Escala de visualização de eixos. |
| **6, 16, 18**| *Legacy Bloat* | N/A | Reservado para uso interno do kernel (Não-Expressivo). |
| **25-43** | *Ambiguity* | N/A | IDs não mapeados em caches locais (Zero-Inference). |

---

## 3. Catálogo de Componentes ("Os Parafusos")

### 3.1. Física do Layout (Crucible Formula)
O posicionamento absoluto é governado pela conversão de **DPI Screen (96)** para **ISO 216 (A4)**.
- **Fórmula**: $Medida[mm] = (Medida[px] / 96.0) * 25.4$
- **Z-Index**: Atribuído sequencialmente. SHAPES (rect) recebem `pointer-events: none` para não bloquear inputs.

### 3.2. Decomposição de Objetos
- **formatted-label**: Renderiza HTML sanitizado. Suporta tags `<b>`, `<i>`.
- **dynamic-table (GRID)**: Mapeia para Propriedade 35. Requer cabeçalho dinâmico via SQL.
- **rect (SHAPE)**: Moldura visual. No Emitter Web, é um `div` com borda fixa.
- **image-marker**: Permite desenho sobre canvas de fundo (Ex: Anatomia Humana).

---

## 4. Motor de Integração e Persistência

### 4.1. Prevenção de SQL Injection & Macros
O sistema utiliza **Variable Injection via SmartDB**. O transpilador deve preservar macros nativas:
- `&<PAR_CD_ATENDIMENTO>`: Identificador da consulta/internação.
- `&<PAR_CD_PACIENTE>`: Identificador único do paciente.
- `&<PAR_USUARIO_LOGADO>`: Contexto de autorização.

### 4.2. Mapeamento de Tabelas Oracle
- **Pagu_Objeto_Editor**: Tabela central de metadados de campos.
- **Pagu_Metadado_P**: Armazenamento de valores de propriedades (VL_PROPRIEDADE).
- **Pagu_Documento_E**: Cabeçalho dos formulários transpilados.

---

## 5. Justificativa Estratégica (O "Pra que serve")
A arquitetura Réplica MV suporta a **Soberania Digital da Saúde**:
1. **Digitalização Contínua**: Transforma o "Papel Binário" (Jasper) em "Lógica Viva" (JSON/AST).
2. **Rastreabilidade Forense**: Garante que regras clínicas de 10 anos atrás produzam o mesmo resultado no Emitter moderno.
3. **Conformidade CFM**: Mantém a integridade do registro eletrônico de saúde (PEP) em transições de plataforma por manter o hash MD5 consistente com a assinatura digital original.

---

## 🛡️ Checklist de Validação Tripla (VT-3)
- [ ] **Bit-Perfect**: O hash MD5 gerado pelo novo transpilador é aceito pelo Soul MV?
- [ ] **Escapement**: Blocos PL/SQL contendo `&` foram escapados sem perda semântica?
- [ ] **Crucible**: O formulário gerado em A4 possui paridade milimétrica com o impresso do Editor 2?

**Assinatura**: *Antigravity System Architect* [ECP-ACTIVE]
