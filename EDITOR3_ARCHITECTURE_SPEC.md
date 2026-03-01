# [PROTOCOL VT-3] ESPECIFICAÇÃO ARQUITETURAL: MV EDITOR 3 (FLOW EDITOR)
**Data de Homologação:** 24 de Fevereiro de 2026 (e.c.)
**Alvo da Engenharia Reversa:** Motor de Renderização Editor 3 (HTML5 / Server-Driven UI)
**Objetivo:** Desacoplamento de Vendor Lock-in e mapeamento do contrato REST/JSON para persistência agnóstica via Java/Electron.

## 1. Topologia da Camada de Transporte
A análise dinâmica confirmou o abandono do Adobe AVM2/AMF. O Editor 3 opera com padrões Web modernos, porém encapsulando regras legadas de persistência.

* **Protocolo de Comunicação:** HTTP/HTTPS via requisições REST (Fetch/XHR).
* **Content-Type:** `application/json`
* **Endpoints Críticos Identificados:**
    * `POST /editor/executor/api/editor/registries` (Gravação de Estado/Documento)
    * `POST /editor/executor/api/editor/registries/load` (Leitura de Estado/Documento)
* **Comportamento Clínico:** O sistema adota uma abordagem de Server-Driven UI. A tela não possui formulários HTML estáticos (`<form action>`); todo o DOM é desenhado dinamicamente pelo frontend (Angular/Vue/React) com base em um dicionário JSON devolvido pelo backend.

## 2. Anatomia do Payload de Mutação (The Split-State Paradigm)
Diferente do Editor 2, que reenviada um XML monolítico, o Editor 3 divide a responsabilidade no momento do salvamento (Save State). O Payload enviado ao backend é um objeto composto por metadados relacionais e dois grandes blocos:

```json
{
  "closed": false,
  "fieldAnswers": {
    "115244": { "value": "ANTIGRAVITY_TEST", "type": "flex-textarea" },
    "115250": { "value": "Não", "type": "radiobutton" }
  },
  "content": "{\\\"pageBody\\\":{\\\"children\\\":{ ... }}}",
  "layoutId": 3310,
  "system": "MVEDITOR",
  "parameters": {
     "PAR_CD_ATENDIMENTO": 654,
     "PAR_CD_PACIENTE": 82217,
     "PAR_CHAVE": 236390
  }
}
2.1. O Nó fieldAnswers (A Chave da Tradução)É aqui que os agentes devem focar. É um dicionário limpo onde a chave é o id numérico do componente no banco Oracle, e o valor é um objeto contendo o texto preenchido e o tipo do componente.2.2. O Nó content (O Legado Escapado)Contém a "Árvore da Verdade" do layout. É um JSON transformado em string escapada ("{\"pageBody\":..."). O motor Java/Electron deve preservar e devolver esta string intacta ao salvar, caso o backend MV ainda a utilize para validar a assinatura ou renderizar relatórios PDF.3. O Falso HTML5 e as Coordenadas Absolutas[Ceticismo Técnico - Risco Crítico]Embora trafegue JSON para a web, a MV não utiliza HTML5 fluido (Flexbox/CSS Grid). O JSON do content descreve cada elemento com coordenadas matemáticas absolutas (x, y, width, height, zIndex).Motivo: Compatibilidade com o MV Report (Oracle Reports) na hora de imprimir o prontuário.Diretriz para o Electron: O gerador de UI não pode usar layouts responsivos web. Deve-se instanciar um Canvas ou um container div com position: relative e alocar os filhos em position: absolute respeitando milimetricamente o eixo X e Y fornecido no JSON. Ignorar isso causará truncamento e sobreposição de dados clínicos.4. Dicionário de Componentes e Normalização (Editor 3)O novo motor alterou as nomenclaturas e a tipagem. Os agentes Java devem mapear os dados da seguinte forma no bloco fieldAnswers:Modern Type (Editor 3)Equivalente (Editor 2)Comportamento de Serialização (Valor)flex-textarea / flex-textTEXTAREA / TEXTString pura.radiobuttonRADIOBUTTONAtenção: Regressão arquitetural. Em vez de booleanos, envia a String do rótulo (Ex: "Sim" ou "Não").flex-comboboxCOMBOBOXString. Ainda mantém delimitadores internos ou IDs dependendo da lista de valores anexada (Ex: `"1formatted-labelLABELApenas renderização (CSS inline no HTML embutido). Não vai para fieldAnswers.5. Âncora de Contexto (Parameters)Assim como no Editor 2, o nó parameters é intocável. Ele contém as chaves primárias do banco Oracle (PAR_CD_ATENDIMENTO, PAR_CD_PACIENTE). O tradutor Antigravity deve garantir que essas chaves originais sejam injetadas no Payload REST ao salvar, sob pena de erro de Constraint Violation no PL/SQL.

## 1. Topologia da Camada de Transporte e Endpoints Clínicos
O Editor 3 opera sob um modelo transacional assíncrono. O estado do documento não é processado localmente; o cliente atua apenas como um espelho de renderização.

**Endpoints Mapeados:**
* `POST /editor/executor/api/editor/registries` -> Responsável pelo *Commit* (Salvamento) do documento final.
* `POST /editor/executor/api/editor/registries/load-paginated` -> Recupera o estado inicial de documentos longos (paginação de *scroll* de dados).
* `POST /editor/designer/api/versions/active?documentId={id}` -> Recupera o esqueleto do *Layout* puro antes do preenchimento.
* `POST /editor/executor/api/editor/registries/applyRulesByFieldId` -> **[CRÍTICO]** Endpoint do Motor de Regras. Disparado em eventos de `onBlur` ou `onChange` para recalcular dados no servidor (Ex: calcular IMC).

## 2. A Dupla Arquitetura do Payload de Mutação (Split-State)
O envio de dados no momento da gravação contém dois vectores principais. O gerador Java deve serializar este objecto com precisão milimétrica.

### 2.1. Vector de Valores (`fieldAnswers`)
Mapeamento chave-valor (Dicionário) exclusivo para componentes mutáveis.
```json
"fieldAnswers": {
  "115240": { "value": "Sim", "type": "radiobutton" },
  "115243": { "value": "24/02/2026", "type": "flex-text" }
}
Ceticismo Técnico: A chave (115240) representa o CD_OBJETO ou instância única na tabela do Oracle. Não é o identificador textual do campo.2.2. Vector de Estrutura (content Escapado)O content é uma enorme String contendo um JSON escapado. Representa a árvore do Document Object Model (DOM) proprietário da MV.Estrutura Interna do Content:pageBody -> children -> {ID_Componente: Propriedades}3. Dissecção do Dicionário de Componentes (O JSON Interno)O motor Electron deve fazer o parse (deserialização) da String content para construir a interface. Cada nó filho possui atributos de persistência e atributos de estilo (coordenadas absolutas).Atributos Comuns Irredutíveis:id (Integer): ID de Instância (ex: 115234).metadado (Integer): Mapeia para o CD_PROPRIEDADE do MV (ex: 82326). Indica o tipo clínico (Evolução, Peso, etc.).identifier (String): O sufixo lógico (ex: METADADO_P_572039_1). Útil apenas para debugging, inútil para o banco.x, y, width, height (Integer): Coordenadas matemáticas absolutas. Devem ser injectadas no style do elemento HTML no Electron (position: absolute; left: {x}px; top: {y}px;).style (Object): Dicionário CSS puro (fontFamily, fontSize, zIndex).Especificidades de Tipos:ComponentePeculiaridades Mapeadas no JSONflex-textareaContém maxLength e reprocess: true. Define se o texto pode conter RTF ou HTML embutido.radiobuttonContém a matriz jradio. O Editor 3 estrutura os radios definindo o tamanho da fonte e cor independentemente dentro desta array de objectos. Contém o atributo cascadeRule: true (se afecta outros campos).flex-comboboxO array valuesList pode vir vazio [], pois as opções podem ser carregadas do banco via DUAL (requisição secundária).formatted-labelO valor reside no identifier em forma de HTML bruto (Ex: <p><span style="color: #000000">Motivo:</span></p>). Não possui input de utilizador.4. O Motor de Regras em Tempo Real (ruleTarget)No seu log, os componentes possuem os atributos:"ruleTarget": true, "ruleTargetTypes": "validate" ou "answer"Como o Tradutor (Electron) deve operar:Sempre que o utilizador alterar o valor de um campo onde ruleTarget == true.O Frontend não tenta calcular nada.Ele empacota o JSON de fieldAnswers actual e faz um POST para applyRulesByFieldId.O backend MV devolve o JSON modificado (ex: se marcou "Sim" no RDB_Febre, o servidor devolve o JSON mandando habilitar o TXT_Temperatura).O Electron actualiza o ecrã com base na resposta.5. Âncora de Contexto (O Bloco parameters)A integridade clínica exige o envio estrito das chaves primárias. O Tradutor Java deve interceptar estas chaves na abertura do documento e garantir que não sofrem mutação:JSON"parameters": {
  "PAR_SISTEMA": "MVPEP",
  "PAR_CD_ATENDIMENTO": 654,
  "PAR_CD_PACIENTE": 82217,
  "PAR_INTERNO_MODO_VERSAO": "PUBLICADO",
  "PAR_CHAVE": 236390,
  "PAR_USUARIO_LOGADO": "SES50002"
}
Risco de Falsidade Ideológica: Se o campo PAR_USUARIO_LOGADO for omitido ou adulterado pelo motor replicador, o sistema MV poderá assinar o prontuário no nome de outro profissional (DBAMV), causando quebra de validade jurídica.6. Pipeline de Implementação do Replicador JavaO agente construtor deve estruturar as classes:MVDocumentPayloadDTO.java (Classe base que engloba closed, layoutId, system, parameters).FieldAnswersMap.java (Um HashMap<String, MVFieldAnswerDTO>).ContentParser.java (Utilitário Jackson/Gson que converte a String escapada do content numa estrutura hierárquica PageBodyDTO para extrair as posições X e Y e renderizar no Electron).