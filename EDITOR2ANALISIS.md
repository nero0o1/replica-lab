# [PROTOCOL VT-3] ESPECIFICAÇÃO ARQUITETURAL: MV EDITOR 2 (LEGADO)
**Data de Homologação:** Fevereiro de 2026 (e.c.)
**Alvo da Engenharia Reversa:** Motor de Renderização Editor 2 (Flash/Flex)
**Objetivo:** Desacoplamento de Vendor Lock-in e migração estrutural para Java/Electron.

## 1. Topologia da Camada de Transporte (O Invólucro)

A análise dinâmica de rede revelou que o Editor 2 não opera sob o DOM HTML5 tradicional. Ele é um artefato **Adobe Flex / Flash Player** executado em uma máquina virtual cliente (AVM2). 

* **Protocolo de Comunicação:** AMF (Action Message Format) via HTTP POST.
* **Content-Type:** `application/x-amf`
* **X-Requested-With:** `ShockwaveFlash/32.0.0.371`
* **Endpoint Alvo:** `/messagebroker/editor/amf` (RemotingMessage / Flex Messaging)
* **Comportamento Clínico:** O estado da aplicação (State Tree) não reside em variáveis JavaScript (`window`), mas sim na memória isolada do binário Flash, sendo encapsulado e serializado em binário AMF no momento do salvamento.

## 2. A Árvore da Verdade (Gramática XML Irredutível)

O núcleo do documento clínico — a "filosofia do sistema" — não está em tabelas relacionais no momento da edição, mas sim em uma **string XML monolítica** embutida dentro do payload AMF. 

A estrutura de coordenadas é **Absoluta** (Desktop-like), não fluida (Web-like). O novo motor Electron deve respeitar a exata métrica de pixels para garantir a paridade na quebra de páginas de impressão no Oracle Reports.

### 2.1. Estrutura do Container Base
```xml
<Application>
  <Page width='768' pageNumber='1' border='false'>
    <Row height='1560' pageSection='pagebody'>
      <Column width='759'>
        </Column>
    </Row>
  </Page>
</Application>
3. Dicionário de Componentes (Mapeamento de Engenharia)Para o tradutor autônomo reconstruir os documentos da MV, ele deve parsear as seguintes tags XML e convertê-las para o modelo JSON/Electron:Tag Legacy (XML)Atributos CríticosInterpretação no Tradutor (Java/Electron)<LABEL>x, y, width, heightO conteúdo é injetado via <htmlText><TEXTFORMAT>. Exige parser para remover tags proprietárias do Flash.<TEXTAREA>key, id, maxCharsCampo de texto livre (CLOB). O key (ex: TXT_observacoes...) é a chave de ligação com a tabela EDITOR_PROPRIEDADE.<RADIOBUTTON>key, id, selectedCampo booleano/binário. Normalmente agrupado por prefixo RDB_.<GROUP>x, y, width, heightContainer invisível que engloba elementos (geralmente agrupa radio buttons para exclusão mútua).<IMAGE>key, id, width, heightRepresenta marcações estáticas (ex: termômetro, setas, mapas de dor clínica).<DATE>key, id, borderStyleComponente de data (ex: DAT_Data_Obito). Exige formatação ISO8601 no tráfego, mas máscara DD/MM/YYYY na UI.4. Matriz de Risco e Ceticismo TécnicoPara evitar perda estrutural dos documentos construídos nos últimos 5 anos, o sistema replicador deve adotar as seguintes travas de segurança:Risco de Renderização (Truncamento Clínico): A tag <Page width='768'> é imperativa. Se o Electron renderizar a interface em 100% width (responsivo), a impressão do prontuário no sistema original ficará desfigurada. A tela de edição deve ser um Canvas/Container de tamanho fixo.Risco de Sanitização HTML: As strings de texto dentro de <LABEL> usam formatação antiga (<FONT FACE="Verdana" SIZE="10">). O motor Java no backend deve limpar ou traduzir isso para CSS inline ao salvar, caso o banco de dados exija o texto puro.Mapeamento de IDs: O atributo id='1117217' gerado no XML refere-se à chave primária real do objeto no banco Oracle (CD_OBJETO). O sistema não deve usar o key (nome em string) como identificador único relacional, apenas o id numérico.5. Diretriz de Implementação para o TradutorO pipeline de conversão no Backend Java deverá seguir o modelo:Input (Exportação/Payload AMF) -> Deserializador Flex/AMF -> Extrator Regex/DOM do XML interno -> Conversor de Coordenadas Absolutas -> Output JSON (Electron UI).
---

# [PROTOCOL VT-3] ESPECIFICAÇÃO DE ESTADO E MUTAÇÃO: MV EDITOR 2
**Data de Homologação:** Fevereiro de 2026 (e.c.)
**Alvo da Engenharia Reversa:** Mecanismo de Persistência e Regras (Motor Legado AVM2)
**Objetivo:** Instruir agentes autônomos a construir o módulo de tradução e gravação em Java/Electron sem corromper assinaturas digitais ou triggers PL/SQL do Oracle.

## 1. O Paradigma do "Terminal Burro" (State Mutation)

O Editor 2 não salva objetos JSON isolados. Ele opera sob o paradigma de **Mutação de Árvore Completa**. Para gravar qualquer dado no banco, o motor deve reenviar a estrutura XML integral do documento, embutindo os valores digitados pelo usuário em nós filhos específicos.

**Ação Obrigatória do Electron (Frontend):** Manter a árvore XML base carregada em memória. Ao receber um comando de "Salvar", o motor não deve gerar um novo documento, mas sim injetar (ou atualizar) a tag `<answer>` dentro do nó correspondente ao `id` numérico do componente.

### Exemplo de Injeção de Estado:
```xml
<TEXT key="peso_strong_1" id="1115502" width="55" ... ></TEXT>

<TEXT key="peso_strong_1" id="1115502" width="55" ... >
    <answer>ANTIGRAVITY_TEST</answer>
</TEXT>
2. Dicionário Irredutível de Tipos Primitivos (Gramática MV)O banco de dados Oracle rejeitará ou corromperá a leitura se os tipos enviados não seguirem estritamente as regras de serialização abaixo. Agentes geradores de código devem implementar Parsers rígidos para estas conversões:Componente UICast Java/ElectronFormato de Retorno na tag <answer>Risco ClínicoTEXT / TEXTAREAStringTexto puro ou RTF. Ex: <answer>Dor abdominal</answer>Truncamento em limite de maxChars.RADIOBUTTON / CHECKBOXBooleanExtrito: <answer>true</answer> ou <answer>false</answer>Usar "1/0" ou "S/N" causa falha de TypeMismatch no backend Java da MV.COMBOBOXString (Delimitada)Uso de separador `3. O Motor de Regras Desacoplado (Backend Execution)A inteligência de cálculos clínicos (ex: IMC, Scores de Risco) não reside no Frontend. O Editor 2 é passivo.Arquitetura de Emulação no Electron:Para disparar eventos como onChange (ex: usuário altera o "Peso"), o Electron deve:Atualizar a tag <answer> na árvore XML local.Disparar uma requisição AMF applyRulesByFieldId ou applyRulesOnClick para o backend MV, enviando o XML modificado e o ID do campo gatilho.O Backend MV (Oracle/Java) realizará o cálculo e devolverá um novo XML inteiro com os resultados preenchidos (ex: o campo IMC preenchido com <answer>0.08</answer>).O Electron extrai os novos nós <answer> e atualiza o DOM (Re-render).4. O Contexto Clínico (The Metadata Anchor)No final da árvore XML, reside o bloco <parameters>. Este bloco é a âncora relacional que liga o documento desenhado solto na tela à admissão do paciente no hospital. Se o Electron omitir estas tags no momento do salvamento, o Oracle gerará um erro de constraint (ORA-01400: cannot insert NULL into PW_DOCUMENTO_CLINICO.CD_ATENDIMENTO).Mapeamento Crítico:PAR_CD_PACIENTE: Chave primária do Paciente.PAR_CD_ATENDIMENTO: Chave primária do Atendimento (Visita).PAR_INTERNO_MODO_VERSAO: Define se é Rascunho ou Assinado (PUBLICADO).PAR_CHAVE: ID de controle de transação temporal.5. Instrução Direta para Agentes Autônomos de CódigoRegra 1: Nunca modifique as coordenadas originais (x, y, width, height) ao transitar o XML de volta para o servidor. Elas são essenciais para o checksum.Regra 2: Ao criar classes de Entidade em Java para representar o XML, não use conversores genéricos de JSON-to-XML. Crie um DocumentSerializer dedicado que respeite o mapeamento do tópico 2.Regra 3: O tráfego de rede utiliza Adobe AMF. O backend Java (Antigravity) deve utilizar uma biblioteca (ex: BlazeDS ou GraniteDS) para decodificar o binário POST do Flex antes de aplicar a extração de Regex/DOM.
---
