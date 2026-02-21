**Objetivo:** Estabelecer restrições inegociáveis de segurança e integridade referencial para a IDE Antigravity. O não cumprimento destas diretrizes resultará na geração de formulários corrompidos que causarão falhas de gravação nos bancos de dados Oracle do MV ou Tazy, impactando diretamente o registro de dados do paciente e a segurança clínica.

---

## 1. Proibição Absoluta de Identificadores Duplicados
A duplicação de chaves identificadoras causa colisões de namespace no front-end (Angular/React) do Prontuário Eletrônico e corrompe o mapeamento relacional no banco de dados na hora de salvar a evolução clínica.

* **Restrição:** É terminantemente proibido gerar, copiar ou clonar componentes que resultem em duplicidade das chaves `id` (numérico), `code` (numérico) ou `identifier` (string) dentro do mesmo escopo do documento.
* **Regra de Engenharia:** Ao instanciar um novo componente no JSON, a engine deve gerar um `identifier` único (ex: prefixo do tipo + hash ou timestamp, como `TEXTO_H09GA54G`).
* **Gatilho de Bloqueio (Hard Fail):** O parser da IDE deve executar uma varredura de contagem de identificadores no array `children`. Se `count(identifier) > 1` para o mesmo valor, a compilação deve ser abortada imediatamente.

## 2. Preservação Mandatória de Metadados de Auditoria
Sistemas de saúde operam sob estrita regulação legal (CFM, SBIS, LGPD). O rastreio de quem criou ou importou um documento é imutável. A perda desses dados configura violação de auditoria.

* **Campos Protegidos (Read-Only):**
    * `criado_por` (ID 10)
    * `criado_em` (ID 24)
    * `publicado_em` (ID 26)
    * `ultima_publicacao_por` (ID 25)
    * `importado` (ID 33)
    * `migrado` (ID 34)
* **Regra de Operação:** O agente Antigravity **não tem permissão** para sobrescrever, modificar, recalcular ou remover estes nós do JSON durante processos de refatoração, otimização ou conversão.
* **Comportamento Exigido:** Estes dados devem sofrer *Pass-Through* (transmissão 1:1) do arquivo de origem para o arquivo de destino. Em caso de criação de um documento 100% do zero, a IDE deve preencher `criado_por` com a matrícula do usuário logado e `criado_em` com o timestamp ISO-8601 atual. O agente não deve alucinar matrículas de usuários.

## 3. Higienização de Inputs SQL e Prevenção de Injeção
Documentos eletrônicos frequentemente executam consultas ativas ao banco de dados para popular listas (`COMBOBOX`), buscar dados de pacientes ou executar macros. Isso ocorre predominantemente através da propriedade `acao` (ID 4) ou `acao_texto_padrao` (ID 13).

* **Isolamento de Operações (Read-Only):**
    * Qualquer instrução SQL embutida no formulário deve ser restrita exclusivamente a operações de leitura (`SELECT`).
    * **Proibição de Comandos DML/DDL:** É expressamente bloqueado inserir strings que contenham os seguintes comandos: `INSERT`, `UPDATE`, `DELETE`, `DROP`, `ALTER`, `TRUNCATE`, `GRANT`, `REVOKE`, `EXECUTE`, `COMMIT`, `MERGE`.
* **Sanitização de Caracteres e Escapes:**
    * O agente deve assegurar que o conteúdo SQL esteja envelopado corretamente e não rompa o encapsulamento do JSON.
    * Tentativas de escape prematuro de aspas simples (ex: `'; --`) devem ser neutralizadas. Se a IDE detectar sequências anômalas comuns em ataques de SQL Injection dentro das strings de metadados, a inserção deve ser bloqueada.
* **Controle de Quebra de Linha:**
    * Instruções SQL não podem conter caracteres de controle corrompidos (como `\r` isolados). Devem ser formatadas com `\n` e escapadas para `\\n` no momento do `JSON.stringify()`, evitando que o interpretador backend do hospital falhe na compilação da query.

## 4. Consistência de Restrições Clínicas
O banco de dados espera tipos de dados específicos para cada coluna de evolução. O bypass dessas restrições gera erros de inserção na tabela final do paciente.

* **Choque de Lógica Editável/Obrigatório:** Um componente não pode ter a propriedade `obrigatorio` (ID 8) definida como `true` se a propriedade `editavel` (ID 7) estiver definida como `false`. Se o campo não pode ser editado pelo médico, ele não pode bloquear o salvamento da tela por estar vazio e ser obrigatório. O agente deve identificar e corrigir essa anomalia estrutural forçando `obrigatorio: false`.
* **Compatibilidade de Máscara (ID 3):** Componentes do tipo `DATE` ou campos formatados não podem receber `valor_inicial` (ID 9) que fuja da restrição da máscara (ex: inserir string "SEM DATA" em um componente de data).

Validação de Domínios Fechados (lista_valores - ID 52): Em componentes do tipo RADIOBUTTON ou COMBOBOX que representam dados clínicos críticos (ex: Tipos Sanguíneos, Lateralidade, Vias de Administração de Medicamentos), a engine da IDE não tem permissão para alterar ou "corrigir" os valores de chave-valor (ex: de 1=Oral|2=Intravenosa para O=Oral|I=Intravenosa). A alteração das chaves do dicionário corrompe a decodificação de prontuários antigos no banco de dados.5. Integridade Estrutural e Visibilidade ClínicaA perda de dados visuais no front-end pode levar a erros de conduta médica (ex: um campo de "Alergias" que não é renderizado na tela devido a um erro de aninhamento).Prevenção de Nós Órfãos (Orphan Nodes):Todo componente que declarar um fieldParentId ou fieldParentIdentifier deve ter a garantia absoluta de que o nó pai existe no escopo do pageBody.Gatilho de Bloqueio: Se a compilação gerar um componente filho apontando para um pai inexistente, a IDE deve barrar a exportação, pois isso causa tela em branco (White Screen of Death) no módulo de atendimento do MV.Segurança em Seções Condicionais (CONDITIONAL-SECTION):Lógicas de ocultação (Hide/Show) baseadas em regras de negócio (ID 22) devem possuir um comportamento de fallback seguro.Se uma variável de controle de regra for omitida, a seção condicional deve assumir o estado active: true e editable: false por padrão, garantindo que a informação clínica seja pelo menos visualizada pelo médico, mesmo que não editável, prevenindo a ocultação acidental de dados de triagem.6. Blindagem de Interoperabilidade (FHIR / HL7)Com a adoção do Prontuário Web e integrações via API RESTful, os formulários gerados atuam como contratos de dados.Nomenclatura Estrita de Chaves de API (descricao_api - ID 31):Se a propriedade expor_para_api (ID 29) estiver marcada como true, o campo descricao_api torna-se a chave do payload JSON no barramento de integração do hospital.Regra de Sanitização: O valor de descricao_api não pode conter espaços, acentos, caracteres especiais (exceto _) ou iniciar com números.Ação: O agente Antigravity deve converter automaticamente strings inválidas (ex: "Pressão Arterial" $\rightarrow$ "pressao_arterial") antes da injeção.Proibição de Tipagem Ambígua em Integrações:Componentes numéricos exportados para API (NUMBER(p,s)) não podem ter a máscara (ID 3) configurada para injetar símbolos de formatação nativa (como R$ ou %) no valor bruto. O valor bruto deve permanecer puro para evitar falhas de cast nos sistemas de faturamento e mensageria HL7.7. Versionamento e Imutabilidade de Prontuários (Assinatura Digital)Formulários clínicos, uma vez utilizados e assinados digitalmente (Certificado ICP-Brasil), não podem sofrer mutações que alterem o contexto de respostas passadas.Regra de Evolução de Layout (versionId e hash):Ao modificar um formulário existente (Update), a IDE não deve excluir componentes (DELETE), mas sim inativá-los (active: false). A deleção física de um componente que já possui respostas em tabelas de evolução clínica causa falha de integridade referencial (Constraint Violation) no Oracle.Comportamento Exigido: Se o usuário solicitar a "remoção" de um campo legado, o agente deve traduzir a intenção para uma operação de Soft Delete, alterando a propriedade visual para oculto e active para false, mantendo seu identifier intacto no arquivo JSON final.8. Gatilhos de Auditoria e Abstenção (Anti-Alucinação)Para manter o rigor arquitetural e evitar que o modelo de linguagem (LLM) da IDE tente "adivinhar" configurações clínicas complexas:Se a solicitação do usuário envolver a criação de fórmulas matemáticas (ID 38 - Cascata de Regra) para cálculos clínicos (ex: Cálculo de IMC, Clearance de Creatinina, Escore de Glasgow) e a fórmula fornecida no prompt for ambígua ou incompleta:Ação do Agente: Acionar ABSTENÇÃO CONTROLADA. O agente está expressamente proibido de preencher as lacunas da fórmula clínica com conhecimento próprio não verificado.O sistema deve gerar o componente, deixar a chave regras_usadas (ID 22) vazia ou com stub seguro, e solicitar ao desenvolvedor que forneça o script SQL/Lógica exata homologada pela área de negócios do hospital.

# Guardrails de Segurança e Integridade Clínica

## Regras de Tolerância Zero
1. **Preservação de Lógica de Negócio:** Qualquer instrução `SELECT`, `UPDATE` ou lógica PL/SQL encontrada na propriedade `acao` (ID 4) ou `regras_usadas` (ID 22) deve ser transcrita de forma literal, mantendo espaçamentos, aspas e quebras de linha. O motor NÃO deve tentar corrigir erros de sintaxe no código SQL contido nestes campos.
2. **Isolamento de Execução:** O próprio ReplicaEditor não executará os SQLs contidos nos documentos. Eles são tratados apenas como payloads de texto.
3. **Auditoria Metadados:** Os campos `criado_por` (ID 10), `criado_em` (ID 24) e `publicado_em` (ID 26) são sagrados. Se o arquivo destino não suportar esses campos, o processo de exportação deve ser abortado com log crítico.