**Objetivo:** Instruir a conversão sistemática e determinística dos artefatos legados do sistema MV (IDs numéricos e tipagem Oracle) para uma estrutura JSON universal e neutra, permitindo processamento automatizado por ferramentas IDE/agentes.

## 1. Mapeamento de Propriedades (Dicionário de Metadados - CD_PROPRIEDADE)
A estrutura JSON deve substituir as chaves numéricas opacas presentes no backend Oracle pelos identificadores literais (JSON Keys) abaixo, garantindo legibilidade e padronização.

| ID (MV) | Identificador Universal (JSON Key) | Descrição Semântica / Contexto Operacional |
|:---:|---|---|
| 1 | `tamanho` | Define o tamanho estrutural do componente. |
| 3 | `mascara` | Máscara de formatação de entrada de dados. |
| 4 | `acao` | Instrução de query (ex: instrução SQL SELECT associada) ou ação do componente. |
| 5 | `usado_em` | Contador de layouts ou documentos em que o campo está inserido. |
| 7 | `editavel` | Flag que define permissão de edição do componente. |
| 8 | `obrigatorio` | Restrição de preenchimento obrigatório. |
| 9 | `valor_inicial` | Valor padrão instanciado no carregamento. |
| 10 | `criado_por` | Matrícula/login do usuário criador do artefato. |
| 13 | `acao_texto_padrao` | Ação ou query de execução para o texto padrão. |
| 14 | `texto_padrao` | Texto estático ou dinâmico de exibição padrão. |
| 17 | `reprocessar` | Flag que comanda reprocessamento de ação em cascata. |
| 18 | `lista_icones` | Relação de ícones acoplados ao componente. |
| 22 | `regras_usadas` | Regras de negócio ou lógicas atreladas. |
| 24 | `criado_em` | Timestamp de criação original. |
| 25 | `ultima_publicacao_por` | Usuário responsável pela última publicação. |
| 26 | `publicado_em` | Timestamp da última publicação aprovada. |
| 29 | `expor_para_api` | Flag de autorização para tráfego via endpoints RESTful. |
| 30 | `hint` | Texto de dica / Tooltip de interface. |
| 31 | `descricao_api` | Chave de documentação/contrato para mapeamento em formato Swagger/OpenAPI. |
| 32 | `tipo_moeda` | Especificação técnica do formato monetário. |
| 33 | `importado` | Identificador de artefato proveniente de carga de arquivo externo. |
| 34 | `migrado` | Flag de controle para rotinas legadas (migração Editor 2 para Editor 3). |
| 35 | `tipo_do_grafico` | Categoria de renderização gráfica (ex: PIE, BAR). |
| 38 | `cascata_de_regra` | Acionador de encadeamento de regras sequenciais. |
| 40 | `min_do_grafico` | Parâmetro de teto mínimo do eixo gráfico. |
| 41 | `max_do_grafico` | Parâmetro de teto máximo do eixo gráfico. |
| 50 | `cor_de_fundo` | Código hexadecimal de coloração. |
| 52 | `lista_valores` | Opções de domínio fechado extraídas para o elemento. |

## 2. Regras Estritas de Tipagem (Banco Oracle $\rightarrow$ JSON)
Os metadados extraídos do Oracle devem sofrer coerção forçada para tipos primitivos do JSON, eliminando construtos legados.

* **Tipagem de Texto e Literais:**
    * `VARCHAR2(n)`, `CHAR(n)`, `CLOB` $\rightarrow$ Traduzir estritamente para `string`.
    * Valores lógicos armazenados como strings de um caractere (`'S'`/`'N'` ou `'V'`/`'F'`) devem ser decodificados na camada de extração e mapeados estruturalmente para `boolean` (`true` ou `false`).
* **Tipagem Numérica:**
    * `NUMBER(p, s)` onde `s = 0` (ex: `NUMBER(10,0)` ou `NUMBER(4,0)`) $\rightarrow$ Traduzir estritamente para `integer`.
    * `NUMBER(p, s)` onde `s > 0` (ex: `NUMBER(14,4)`) $\rightarrow$ Traduzir para `number` (ponto flutuante), assegurando padronização do separador decimal (ponto em vez de vírgula).
* **Tipagem Temporal:**
    * `DATE`, `TIMESTAMP` $\rightarrow$ Traduzir para `string`, obrigatoriamente padronizada no formato normativo ISO-8601 (ex: `YYYY-MM-DD HH:mm:ss` ou datetime padrão) para não causar quebras de contrato de API em processos FHIR/OpenEHR.
* **Gestão de Nulos:**
    * Campos inexistentes ou nulos no Oracle $\rightarrow$ Mapear para o literal estrito `null` no JSON (vedada a substituição não autorizada por strings vazias `""`).

## 3. Diretrizes de Mapeamento de Componentes de Interface (`visualizationType`)
Os tipos de renderização dos componentes exigem um mapeamento semântico de propriedades e um conjunto de regras obrigatórias durante a conversão para o schema.

| Tipo (Origem MV) | Categoria Destino | Regras de Compilação e Restrições |
|:---|---|---|
| `TEXT` / `TEXTAREA` | Entrada de Texto | Obrigatório o mapeamento de `tamanho` (ID 1) e `obrigatorio` (ID 8). Bloquear quebras de linha irregulares fora de controle léxico. |
| `FORMATTEDTEXT` | Texto Enriquecido | Preservar aspas de forma isolada, processar codificação escapada para evitar quebra de JSON. |
| `CHECKBOX` | Booleano Múltiplo | Mapear matriz de agrupamento se existente. Valor base processado a partir de `valor_inicial` (ID 9). |
| `RADIOBUTTON` | Escolha Única | Exigir vinculação a um grupo de domínios restritos. Processar validação mútua de `valor_inicial`. |
| `COMBOBOX` | Seleção Dropdown | Mandatório extrair o payload contido em `lista_valores` (ID 52) ou o referencial de `acao` (ID 4) que popula a lista dinamicamente. |
| `DYNAMIC-TABLE` / `GRID`| Matriz Estruturada | Ação de compilação aninhada. Deve possuir nós filhos definindo colunas e suportar instruções SQL no atributo `acao` (ID 4) sem injetar escape incorreto (`\r`). |
| `DATE` | Entrada Temporal | Exigir mapeamento de `mascara` (ID 3). Bloquear alocação de valores fora do padrão de data no payload. |
| `LABEL` | Output Visual | Somente leitura. Vedado mapear propriedades de restrição de entrada, como `obrigatorio` (ID 8) e `editavel` (ID 7) igual a true. |
| `IMAGE` / `IMAGEMARKER` | Mídia Acoplada | Isolar payload binário ou base64 associado. Em caso de marcação, exigir mapeamento do mapa de coordenadas atrelado. |
| `HYPERLINK` / `BUTTON` | Acionador de Evento| Propriedade `acao` (ID 4) atuará como engine principal de roteamento ou script associado. |

## 4. Conformidade do Fluxo de Processamento
A matriz gerada neste formato atuará como esquema canônico da IDE Antigravity. A engine conversora deverá validar o tipo declarado e bloquear construções baseadas em representações sujas (como quebras de linha corrompidas ou tipos numéricos alocados em strings). Se uma propriedade for listada em chaves fora da validação tipada desta arquitetura estrutural, a inserção deve falhar o parser de entrada antes do deploy.

## 5. Estrutura de Hierarquia e Agrupamento (Nesting)
O modelo estrutural do MV baseia-se em um esquema de árvore (nós e folhas). A engine do Antigravity deve mapear rigorosamente a paternidade dos componentes para não corromper a renderização na interface.

* **Atributo `group`:** Define a pasta ou agrupador lógico do componente.
  * Mapeamento obrigatório de `id` e `name` (ex: "Repositório Local").
  * O `itemType` do grupo deve ser traduzido com precisão (ex: `G_CAM` para Grupo de Campos, `R_REP_CAM` para Raiz de Repositório).
* **Atributos `fieldParent` e `fieldParentIdentifier`:** Representam a relação de aninhamento visual (ex: um `CHECKBOX` dentro de um `PANEL` ou uma coluna dentro de uma `DYNAMIC-TABLE`).
  * **Regra de Transição:** Se um componente tem `fieldParentId` preenchido, ele deve ser renderizado como "child" (nó filho) no JSON estrutural da IDE.
* **Seções Condicionais (`CONDITIONAL-SECTION`):** Devem agrupar os arrays de componentes baseados na propriedade `regras_usadas` (ID 22). O nó principal da seção controla o estado de visibilidade (`active` ou `editable`) de todos os filhos.

## 6. Tratamento Avançado de Strings e Consultas SQL (Ação)
Muitos componentes interativos dependem de instruções SQL ou regras lógicas embutidas (especialmente no atributo `acao` - ID 4). O parser deve ser blindado contra corrupção de sintaxe.

* **Higienização de Quebras de Linha:**
  * É **estritamente proibida** a injeção ou manutenção de escapes de quebra de carro (`\r`) não sancionados. Quebras de linha legadas de banco de dados devem ser padronizadas universalmente para `\n`.
* **Preservação de Aspas:**
  * As aspas simples em blocos SQL (ex: `SELECT * FROM PACIENTE WHERE MATRICULA = 'CODIGO'`) devem ser preservadas como literais de string na configuração, assegurando que o JSON escape corretamente aspas duplas, mas mantenha a integridade das aspas simples para o motor Oracle.
* **Injeção de Escape:**
  * Códigos HTML/CSS (comuns em texto formatado ou layouts) devem passar por uma rotina de `Stringify` antes de serem alocados no JSON, evitando a quebra acidental da estrutura de chaves.

## 7. Mapeamento de Layouts e Escopo de Documento
Além das propriedades individuais, o próprio documento (arquivo raiz `.edit` ou equivalente) possui primitivos que precisam de padronização.

| Jargão Legado / Atributo | Identificador Universal | Regra de Mapeamento |
|:---|---|---|
| `documentName` | `nome_documento` | Deve ser uma string alfanumérica, removendo espaços e caracteres especiais fora do padrão `snake_case` ou `camelCase`. |
| `itemType` -> `DOC` / `CAB` / `ROD` | `tipo_artefato` | Traduzir universalmente para `DOCUMENTO`, `CABECALHO` ou `RODAPE`. |
| `width` / `height` | `largura_tela` / `altura_tela` | Coerção forçada para `integer`. Determina a dimensão base da página de renderização. |
| `pageBody.children` | `elementos_pagina` | Array que unifica todas as instâncias de componentes posicionados na tela, acompanhados de suas coordenadas espaciais (`x`, `y`). |

## 8. Segurança, Auditoria e Hash de Integridade
Os metadados que dizem respeito ao histórico do artefato são imutáveis e devem ser tratados como `read-only` no schema de conversão.

* **Rastreabilidade Obrigatória:** Propriedades como `criado_por` (ID 10) e `ultima_publicacao_por` (ID 25) devem refletir a matrícula exata do sistema origem (ex: `SES50002`). A IDE não pode reescrever essas chaves durante o processo de exportação, a menos que o usuário execute um *Save As/Clone*.
* **Hash de Validação:** A chave `hash` (geralmente MD5 no sistema legado, como `b326b506...`) presente em cada propriedade garante a paridade. O gerador do JSON não deve recalcular este hash durante mapeamentos estáticos, mas utilizá-lo como chave de integridade ao comunicar-se com a API do sistema destino para evitar duplicação de inserções (Upsert verification).
* **Bloqueios Lógicos:** Se as propriedades `obrigatorio` (ID 8) e `editavel` (ID 7) entrarem em conflito (ex: um campo marcado como obrigatório, porém não editável `false`), a IDE deve sinalizar um aviso formal de "Lógica Falha" no painel, exigindo intervenção para não paralisar o pipeline de renderização clínica.

# Dicionário de Tradução de Primitivos (MV Editor 2 ↔ Editor 3)

## Objetivo
Mapear as propriedades numéricas legadas para a estrutura JSON RFC 8259, garantindo perda zero de metadados durante o parsing.

## Tabela de Correspondência Absoluta (Propriedades ID)
O motor de transformação deve respeitar este Dicionário de Dados:
- ID 1: `tamanho` (Integer/String)
- ID 3: `mascara` (String)
- ID 4: `acao` (String - SQL/PLSQL)
- ID 5: `usado_em` (Integer)
- ID 7: `editavel` (Boolean)
- ID 8: `obrigatorio` (Boolean)
- ID 9: `valor_inicial` (String/Boolean)
- ID 10: `criado_por` (String)
- ID 13: `acao_texto_padrao` (String)
- ID 14: `texto_padrao` (String)
- ID 15: `parametros_texto_padrao` (String)
- ID 17: `reprocessar` (Boolean)
- ID 19: `barcode_type` (String)
- ID 20: `show_barcode_label` (Boolean)
- ID 22: `regras_usadas` (String)
- ID 24: `criado_em` (DateTime: YYYY-MM-DD HH:MM:SS)
- ID 25: `ultima_publicacao_por` (String)
- ID 26: `publicado_em` (DateTime)
- ID 29: `expor_para_api` (Boolean)
- ID 30: `hint` (String)
- ID 31: `descricao_api` (String)
- ID 32: `tipo_moeda` (String)
- ID 33: `importado` (Boolean)
- ID 34: `migrado` (Boolean)
- ID 35: `tipo_do_grafico` (String)
- ID 38: `cascata_de_regra` (Boolean)
- ID 41: `max_do_grafico` (String/Integer)
- ID 43: `executar_regra_campo_oculto` (Boolean)

## Regra de Tipagem
Valores nulos devem ser tratados estritamente como `null` no JSON. Hashes de propriedades nulas não devem ser calculados (manter `hash: null`).