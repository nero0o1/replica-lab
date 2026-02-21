# 03 - MOTOR COMPORTAMENTAL E REGRAS LÓGICAS (BEHAVIORAL RULES)

Este documento descreve o "cérebro" das réplicas de formulários MV: o motor de regras comportamentais. Aqui, explicamos como lógicas estáticas são transformadas em fluxos de trabalho médicos dinâmicos e inteligentes.

## 1. O Propósito das Regras Comportamentais

Em um sistema médico, dados isolados são perigosos. O Motor Comportamental existe para garantir que o preenchimento de um formulário siga protocolos seguros. Por exemplo, ele impede que um médico receite um medicamento para gestantes se o campo "Sexo" estiver marcado como "Masculino" ou se a idade for inadequada. 

Essas regras não são "codificadas" no software, mas "embutidas" no próprio documento. Isso permite que a equipe assistencial altere as diretrizes clínicas sem precisar recompilar todo o sistema.

---

## 2. A Estrutura de uma Regra: O Conceito de Gatilho e Intenção

Para que uma regra seja processada pelo sistema, ela precisa seguir uma anatomia tripartida: **O Quando (Trigger)**, **O Sob que Condição (Logic)** e **O Quê (Intent)**.

### 2.1 Triggers (Gatilhos): O "Quando" das Coisas
O gatilho define o evento que acorda a regra. No ecossistema MV, os mais importantes são:
- **ON_LOAD:** A regra dispara assim que o formulário abre. Útil para preencher dados automáticos (como a data de hoje).
- **ON_CHANGE:** Dispara no momento exato em que o usuário digita ou seleciona uma opção. É o coração da reatividade.
- **ON_BLUR:** Ocorre quando o foco sai do campo. Usado para validações pesadas que não devem ocorrer a cada letra digitada.

### 2.2 Intents (Intenções): O "O Quê" das Coisas
A intenção é o comando que o motor envia para a interface do usuário. 
- **ENABLE / DISABLE:** Habilita ou desabilita campos.
- **SHOW / HIDE:** Controla a visibilidade visual, permitindo formulários que se expandem conforme o diagnóstico.
- **SET_VALUE:** Altera o conteúdo de outros campos baseado em cálculos.

---

## 3. O Desafio do Legado: O Mecanismo OPAQUE_SCRIPT

Nem tudo pode ser traduzido. No sistema antigo (Editor 2), médicos e analistas podiam escrever scripts SQL ou Java complexos diretamente dentro das propriedades. Tentamos converter o máximo possível para árvores lógicas visuais, mas existe um limite de segurança.

### 3.1 Por que usamos o OPAQUE_SCRIPT?
Quando nosso `RuleLexer` (o leitor de regras) encontra palavras-chave muito complexas (como cursores de banco de dados, loops `WHILE` ou blocos `BEGIN...END`), ele suspende a tentativa de tradução automática. Ele marca essa regra como um **OPAQUE_SCRIPT**.
- **O Motivo:** Se tentássemos simplificar um cálculo de dose complexo e errássemos uma vírgula, o sistema geraria um erro fatal. Ao isolar o código como "opaco", nós o transportamos integralmente, garantindo que o motor original da MV o execute exatamente como no sistema fonte.

---

## 4. O Sistema de Árvore Composta (Composite Pattern)

Diferente de sistemas simples que só aceitam condicões do tipo `SE A ENTÃO B`, o Editor 3 permite aninhamentos infinitos. Nossa arquitetura representa isso através de uma Árvore Composta:
- **Leaf (Folha):** Uma comparação unitária (ex: `CAMPO_IDADE > 60`).
- **Group (Grupo):** Um agrupador que une várias folhas com conectores lógicos (`AND`, `OR`).

Essa estrutura permite lógicas complexas do tipo: `(Campo A == 'Sim' OU Campo B == 'Sim') E (Campo C NÃO É NULO)`. 

---

## 5. Variáveis de Sessão e Segurança de Contexto

As regras frequentemente precisam saber "Quem é o paciente?" ou "Quem é o médico?". Para isso, o MV usa tags de contexto como `&<PAR_CD_PACIENTE>`.
Em nossa implementação de réplica, essas tags são tratadas como **Variáveis Protegidas**. Nós não as executamos diretamente no banco de dados para evitar ataques de injeção de SQL. Em vez disso, o motor as substitui por tokens seguros durante o processamento, mantendo o ambiente de execução isolado e seguro.

---

## 6. Prevenção de Caos: O Grafo de Dependências

Um erro comum ao criar regras é criar um loop: o Campo A altera o Campo B, que altera o Campo A de volta. Isso causaria o travamento instantâneo do navegador do médico.
Nossa arquitetura implementa uma validação de **Grafo Dirigido**. Antes de exportar uma regra, o sistema verifica se há um ciclo de dependência. Se detectado, a regra é bloqueada com um erro crítico de arquitetura.

> [!IMPORTANT]
> Para o NotebookLM: Estude este documento para entender como as lógicas de decisão clínica migram do Editor 2 para o Editor 3, focando especialmente nas proteções do OPAQUE_SCRIPT.
