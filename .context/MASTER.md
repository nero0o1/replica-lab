# MASTER CONTEXT ROUTER - PROJETO RÉPLICA MV

Este documento serve como o sumário executivo e o ponto de entrada principal para a inteligência artificial e para desenvolvedores humanos que operam no projeto Réplica MV. Ele define o propósito do sistema, as fronteiras de conhecimento e as regras de navegação entre os componentes.

## 1. Objetivo do Projeto

O Projeto Réplica MV nasceu da necessidade crítica de garantir a interoperabilidade e a soberania de dados sobre formulários assistenciais complexos. Atuamos na ponte entre o ecossistema legado (Editor 2 - Oracle/XML) e o ecossistema moderno (Editor 3 - JSON/Flow), permitindo a extração, modificação e reinjeção de metadados sem a perda de integridade criptográfica ou funcional.

Nosso sistema não é apenas um conversor de arquivos, mas uma ferramenta de preservação de inteligência clínica. Ao decodificar as regras comportamentais e os mecanismos de hash proprietários, garantimos que lógicas de decisão médica vitais permaneçam operacionais e compreensíveis, mesmo em transições de plataforma tecnológica de larga escala.

---

## 2. Arquitetura do Repositório (Árvore Semântica)

A estrutura abaixo foi desenhada para separar rigorosamente a lógica pura (conhecimento) da implementação técnica e dos ativos brutos.

```text
/replica-editor
├── SKILL.md                       # [GUIDE] Manual de Reconstrução Antigravidade.
├── Rules
│   ├── Dicionaiomvdocs.md
│   ├── INVESTIGACAO_REVERSA_EDITOR_LEGADO.md
│   ├── INVESTIGACAO_REVERSA.md
│   ├── MAPEAMENTO_PRIMITIVOS.md
│   ├── REGRAS_MV.md
│   ├── SEGURANCA_CLINICA_GUARDRAILS.md
│   └── TRANSPILER_XML_JSON.md
├── .context/                   # O Cérebro do Agente (Regras de Arquitetura)
│   ├── MASTER.md               # Este Sumário Executivo.
│   └── architecture.md         # Leis de desenvolvimento e limites de módulos.
├── docs/                       # O Cofre de Conhecimento (Dossiês em Prosa)
│   ├── protocols/              # Governança e Validação (Protocolos Estritos)
│   │   ├── P11_Definitivo_v2.md # Governança SEC-LLM e Classificação de Risco.
│   │   ├──FORENSIC_MASTER_BLUEPRINT.md
│   │   └── VT3_Validacao_Tripla.md # Checklist de Validação Tripla.
│   ├── knowledge_base/
│   │   ├── 01_Criptografia_e_Integridade.md   # [DOC] MD5, Hashes e Validações.
│   │   ├── 02_Mapeamento_Dicionario_Dados.md  # [DOC] Dicionário de IDs e Tipos.
│   │   ├── 03_Motor_Comportamental.md         # [DOC] Regras Lógicas e Gatilhos.
│   │   ├── 04_Arquitetura_Transpiler.md       # [DOC] AST e Mecanismos de Conversão.
│   │   ├── 05_Catalogo_UI_e_Estilizacao.md    # [DOC] Componentes e Design Pixel-Perfect.
│   │   ├── 06_Gerenciamento_de_Sessao.md       # [DOC] Variáveis de Sessão e Contexto.
│   │   ├── 07_Eventos_e_Callbacks.md          # [DOC] Ciclo de Vida e Interações.
│   │   ├── 08_Internacionalizacao.md          # [DOC] Suporte a Múltiplos Idiomas.
│   │   ├── 09_oracle_shadow_logic.md          # [FORENSIC] Triggers e SmartDB Context.
│   │   ├── 10_layout_z_index_matrix.md        # [FORENSIC] Física de Layout e Grid DOM.
│   │   ├── 11_developer_intent_dictionary.md  # [FORENSIC] Dicionário de IDs e Intenções.
│   │   ├── 12_Seguranca_e_Autorizacao.md      # [DOC] Controle de Acesso e Permissões.
│   │   ├── 13_Conversao_Documentos.md         # [DOC] Controle de Acesso e Permissões.
│   │   ├── 14_Auditoria_VT3_Soberania.md      # [DOC] Controle de Acesso e Permissões.
│   │   ├── 15_Dicionario_Etiquetas_Semanticas.md # [DOC] Mapeamento de Magic Numbers.
│   │   └── 16_Motor_de_Blindagem_Interface.md  # [DOC] Resiliência e Serialização.
├── onda1_skeleton/             # Fundação Estrutural (Onda 1)
│   └── skeleton_base.json      # O esqueleto da máquina.
├── notebooklm_reports
│   ├── 01_Arquitetura_Visao_Geral.md
│   ├── 02_Fluxo_de_Dados_e_Logica.md
│   ├── 03_Dependencias_e_Seguranca.md
│   ├── 04_Guia_de_Reconstrucao.md
│   ├── 05_A_Auditoria_Estrutural_e_Containers.md
│   ├── 05_C_Identidade_e_Diferencas_Campos.md
│   ├── 05_D_Matriz_Funcional_Campos.md
│   ├── 05_E_Anatomia_Detalhada_e_Layouts.md
│   ├── 05_F_Anatomia_Comparada_Integral.md
│   ├── DEVELOPER_HANDOVER_GUIDE.md
│   ├── INDEX.txt
│   ├── MASTER_KNOWLEDGE_BASE.md
│   └── walkthrough.md
├── src/                        # O Motor de Código
│   ├── core/                   # Lógica Pura (AST, Hash Engine).
│   ├── importers/              # Conversores de Entrada.
│   ├── emitters/               # Conversores de Saída.
│   │   └── vanilla_web_emitter.py # Emitter Web com Crucible Formula e Quarentena.
│   └── cli/                    # Interfaces de Operação.
│       ├── cli_mass_converter.py  # Processador em lote (Batch Engine).
│       └── test_infusion.html     # Artefato de Prova Técnica (Forensic Infusion).
├─── tests/                      # A Barreira de Qualidade
│   ├── unit/                   # Testes de Componentes.
│   └── integration/            # Testes de Ponta a Ponta.
├───SKILL.md
├─── EDITOR2ANALISIS.md
└─── EDITOR3_ARCHITECTURE_SPEC.md
```

---

## 3. Roteiro de Carregamento de Contexto (Trigger Rules)

Para garantir a máxima precisão nas respostas e evitar a corrupção de arquivos originais, siga rigorosamente as diretrizes de leitura abaixo:

### 3.1 Tarefas de Segurança ou Integridade (Hashes)
Sempre que a tarefa envolver erros de "Invalid Hash", "Mismatch" ou validação de assinaturas no Editor 3, é obrigatório ler o dossiê:
- **Dossiê 01: Criptografia e Integridade.**

### 3.2 Tarefas de Tradução ou Novos Atributos
Se o objetivo for identificar o que um ID numérico significa ou como converter um campo de um formato para outro, consulte:
- **Dossiê 02: Mapeamento e Dicionário de Dados.**

### 3.3 Alterações em Fluxo Clínico e Botões
Para modificações em como o formulário se comporta (esconder campos, cálculos automáticos), o foco deve ser:
- **Dossiê 03: Motor Comportamental.**

### 3.4 Decisões de Engenharia no Código Fonte
Ao mexer na estrutura das pastas `src/importers` ou `src/emitters`, ou ao lidar com arquivos binários Jasper, estude:
- **Dossiê 04: Arquitetura do Transpiler.**

### 3.5 Escavação Arquitetural e "Matéria Escura" (Forensics)
Ao lidar com discrepâncias visuais inexplicáveis, loops de UI ou variáveis de sessão Oracle, consulte:
- **Dossiê 09: Oracle Shadow Logic.**
- **Dossiê 10: Matrix de Layout e Z-Index.**
- **Dossiê 11: Dicionário de Intenção.**

### 3.6 Gerenciamento de Sessão e Contexto
Para entender como o estado é mantido entre interações ou como variáveis de sessão são utilizadas:
- **Dossiê 06: Gerenciamento de Sessão.**

### 3.7 Eventos e Callbacks
Para investigar o ciclo de vida de componentes, gatilhos de eventos ou funções de retorno:
- **Dossiê 07: Eventos e Callbacks.**

### 3.8 Internacionalização e Localização
Para questões relacionadas a múltiplos idiomas, formatação regional ou adaptação cultural:
- **Dossiê 08: Internacionalização.**

### 3.10 Refatoração e Manutenibilidade (Etiquetas)
Para tarefas de substituição de IDs numéricos ou manutenção do dicionário de propriedades:
- **Dossiê 15: Dicionário de Etiquetas Semânticas.**

### 3.11 Resiliência de Interface e Parsing
Sempre que lidar com erros de parsing de strings complexas, aspas ou quebras de linha:
- **Dossiê 16: Motor de Blindagem de Interface.**

---

## 4. Architecture Forensics: Descobertas de "Matéria Escura"

Esta seção rastreia as descobertas de "Matéria Escura" — comportamentos implícitos não documentados no sistema legado que representam risco de regressão. Abaixo, o registro exaustivo de comportamentos legados extraídos via engenharia reversa:

1.  **The Jasper Layout Seal**:
    - **Descoberta**: O XML do Editor 2 (`.edt`) é uma "casca-vazia" para layouts complexos. As coordenadas reais residem no binário `LO_REL_COMPILADO`.
    - **Implicação**: O Emitter deve mimetizar o layout ou injetar fallbacks binários válidos para evitar `EOFException`.
    - **Dossiê Relacionado**: **Dossiê 04: Arquitetura do Transpiler** e **Dossiê 10: Matrix de Layout e Z-Index**.
2.  **Shadow Loop Reentrancy (`cascata_de_regra`)**:
    - **Descoberta**: A Propriedade 38 atua como o bit de terminação de eventos.
    - **Regra**: Sem mimetizar esta propriedade, o navegador entrará em recursão infinita ao processar regras reentrantes.
    - **Dossiê Relacionado**: **Dossiê 03: Motor Comportamental** e **Dossiê 09: Oracle Shadow Logic**.
3.  **Null-Space Insertion vs. PK Corruption**:
    - **Descoberta**: O sistema legigado usa triggers de banco que interpretam IDs negativos como erro ou conflito de sequence.
    - **Solução**: Adotamos a omissão de tags de ID para novos componentes, garantindo a integridade do `NEXTVAL` Oracle.
    - **Dossiê Relacionado**: **Dossiê 02: Mapeamento e Dicionário de Dados** e **Dossiê 09: Oracle Shadow Logic**.
4.  **Crucible Physics (A4 Print Parity)**:
    - **Descoberta**: A resolução de tela do Editor 2 é fixada em 96 DPI, mas o motor de impressão escala via pixels relativos.
    - **Fórmula**: Aplicamos `Pixels / 96 * 25.4` para garantir paridade milimétrica em exportações PDF.
    - **Dossiê Relacionado**: **Dossiê 05: Catálogo UI e Estilização** e **Dossiê 10: Matrix de Layout e Z-Index**.
5.  **Semantic Key Mismatch**:
    - **Descoberta**: Mapeamos o "GAP Semântico" entre IDs numéricos do Oracle e identificadores literais do Editor 3.
    - **Solução**: A `Rosetta Stone` é aplicada em tempo real pelo `RuleLexer` para garantir a consistência.
    - **Dossiê Relacionado**: **Dossiê 02: Mapeamento e Dicionário de Dados** e **Dossiê 11: Dicionário de Intenção**.
6.  **Opaque Script Quarentine**:
    - **Descoberta**: Scripts legados injetados via `LO_REL_COMPILADO` podem conter lógica de negócios crítica, mas são opacos.
    - **Solução**: O Emitter Web isola esses scripts em um ambiente de quarentena (`iframe` com `sandbox`) para execução segura e monitorada.
    - **Dossiê Relacionado**: **Dossiê 04: Arquitetura do Transpiler** e **Dossiê 12: Segurança e Autorização**.
7.  **Wave 1: Strict JSON Ordering**:
    - **Descoberta**: O parser de destino (Editor 3) é sensível à ordem das chaves em certas versões.
    - **Regra**: O Nome deve vir em primeiro, seguido pelo Identificador. A conformidade é garantida pela classe `Onda1Foundation`.
    - **Dossiê Relacionado**: **Dossiê 16: Motor de Blindagem**.
8.  **The Parsing Fragility Peak**:
    - **Descoberta**: Aspas e quebras de linha em campos de texto corrompem a integridade do transporte de metadados.
    - **Solução**: Blindagem atômica via Base64 para garantir que a UI seja transportada como uma "caixa preta" indestrutível.
    - **Dossiê Relacionado**: **Dossiê 16: Motor de Blindagem**.
9.  **Hash Integrity Lock (Anti-Fraud Guard)**:
    - **Descoberta**: Propriedades clínicas no Editor 3 exigem um lacre MD5 para validação de integridade antifraude.
    - **Solução**: Implementação de uma **Look-up Table** estática (`tabela_hashes.py`) que associa valores a lacres homologados, encapsulando-os no formato `{"value": X, "hash": "Y"}`.
    - **Dossiê Relacionado**: **Dossiê 01: Criptografia e Integridade**.
10. **Geometric Memory Crash Protection (Onda 4)**:
    - **Descoberta**: Objetos JSON de layout abertos causam crash de memória no interpretador hospitalar.
    - **Solução**: Técnica de **Dupla Serialização** com Minificação Extrema. O layout é selado como uma string única na chave `content`, utilizando `separators=(',',':')`.
    - **Dossiê Relacionado**: **Dossiê 16: Motor de Blindagem**.
11. **Lexical Shielding (O Inspetor Rigoroso)**:
    - **Descoberta**: Identificadores fora do padrão (acentos, espaços) abortam silenciosamente o carregamento no MV Soul.
    - **Solução**: Barreira de Regex `^(TXT|RDB|CHK|CBB|DAT)_[A-Z0-9_]+$` com política **Fail-Fast** via Exceção Fatal.
    - **Dossiê Relacionado**: **Dossiê 16: Motor de Blindagem**.

### 4.1 Homologação: Operação Forensic Infusion
O motor de ejeção web foi atualizado com as leis de física de layout (Pixels -> Millimeters) e o sistema de quarentena para OPAQUE_SCRIPT. A prova técnica de paridade e segurança reside em:
- [test_infusion.html](file:///j:/replica_lab/batch_test_output/test_infusion.html)

---

## 5. Log de Operações de Engenharia (Chronicle)

Esta seção detalha as principais operações de engenharia e as descobertas técnicas que impulsionaram o desenvolvimento do projeto Réplica MV.

### 5.1 Operação "Behavioral Engine" (AST)
- **Descrição**: Implementação de uma AST (Abstract Syntax Tree) baseada em Composite Pattern para representar e processar lógicas clínicas complexas do Editor 2.
- **Destaque Técnico**: `MvRuleCondition` e `MvBehavioralRule` permitem a transpilação estável de triggers ON_CHANGE, garantindo a fidelidade do comportamento do formulário.
- **Dossiês Envolvidos**: **Dossiê 03: Motor Comportamental**, **Dossiê 04: Arquitetura do Transpiler**, **Dossiê 07: Eventos e Callbacks**.

### 5.2 Operação "Crucible Pipeline" (Batch)
- **Descrição**: Construção do motor de conversão em massa (`cli_mass_converter.py`) e do `StateManager` web para gerenciar o estado dos formulários transpilados.
- **Destaque Técnico**: O `vanilla_web_emitter.py` gera HTML/JS puro com reatividade nativa e um sistema de quarentena robusto para scripts opacos, garantindo performance e segurança.
- **Dossiês Envolvidos**: **Dossiê 04: Arquitetura do Transpiler**, **Dossiê 05: Catálogo UI e Estilização**, **Dossiê 06: Gerenciamento de Sessão**.

### 5.3 Operação "Round-Trip: Edition VT-3"
- **Descrição**: Finalização e validação do ciclo completo de fidelidade documental, testando a conversão bidirecional entre os formatos legado e moderno.
- **Destaque Técnico**: Alcançamos **100% de paridade** no teste `E2 -> E3 -> E2'`, garantindo que nenhum bit de metadado clínico seja perdido no processo de extração, modificação e reinjeção.
- **Dossiês Envolvidos**: **Dossiê 01: Criptografia e Integridade**, **Dossiê 02: Mapeamento e Dicionário de Dados**, **Dossiê 09: Oracle Shadow Logic**.

### 5.4 Operação "Pixel-Perfect Rendering"
- **Descrição**: Desenvolvimento de algoritmos para replicar o layout visual do Editor 2 com precisão milimétrica no Editor 3.
- **Destaque Técnico**: Utilização de uma matriz de Z-Index e cálculo de coordenadas relativas para garantir que todos os componentes sejam renderizados exatamente como no sistema legado, independentemente da resolução.
- **Dossiês Envolvidos**: **Dossiê 05: Catálogo UI e Estilização**, **Dossiê 10: Matrix de Layout e Z-Index**.

### 5.5 Operação "Intent-Driven Mapping"
- **Descrição**: Criação de um dicionário de intenção para traduzir IDs numéricos e abreviações legadas em conceitos claros e funcionais para o Editor 3.
- **Destaque Técnico**: O `developer_intent_dictionary` atua como uma camada semântica, permitindo que desenvolvedores compreendam e manipulem elementos sem conhecimento profundo do legado.
- **Dossiês Envolvidos**: **Dossiê 02: Mapeamento e Dicionário de Dados**, **Dossiê 11: Dicionário de Intenção**.

### 5.6 Operação "Security Hardening"
- **Descrição**: Implementação de medidas de segurança para proteger dados sensíveis e garantir a integridade do sistema durante a transição.
- **Destaque Técnico**: Validação de hashes criptográficos, controle de acesso baseado em funções e quarentena de código externo para prevenir vulnerabilidades.
- **Dossiês Envolvidos**: **Dossiê 01: Criptografia e Integridade**, **Dossiê 12: Segurança e Autorização**.

### 5.7 Operação "Wave 1: Structural Skeleton"
- **Descrição**: Criação da fundação estrutural com ordem de chaves obrigatória e tradução de magic numbers para etiquetas semânticas.
- **Destaque Técnico**: Implementação do módulo `etiquetas_semanticas.py` e do motor `ShieldingEngine` para garantir resiliência total no transporte de componentes.
- **Dossiês Envolvidos**: **Dossiê 15: Dicionário de Etiquetas**, **Dossiê 16: Motor de Blindagem**.

### 5.8 Operação "Onda 3: O Cadeado de Segurança"
- **Descrição**: Implementação de governança antifraude via hashes MD5 estáticos para integridade de prontuários.
- **Destaque Técnico**: Introdução da `tabela_hashes.py` e refatoração do `TradutorRoseta` para encapsulamento atômico de valores com seus respectivos lacres.
- **Dossiês Envolvidos**: **Dossiê 01: Criptografia e Integridade**, **Dossiê 02: Mapeamento de Dados**.

### 5.9 Operação "Onda 4: A Caixa Preta Visual"
- **Descrição**: Implementação de Dupla Serialização minificada para proteção de memória e integridade geométrica de layouts.
- **Destaque Técnico**: Módulo `empacotador_layout.py` garante a redução de ruído (espaços/quebras) no transporte de metadados visuais.
- **Dossiês Envolvidos**: **Dossiê 16: Motor de Blindagem**.

### 5.10 Operação "Onda 5: O Inspetor Rigoroso"
- **Descrição**: Implementação de barreira de validação léxica intransponível para crachás técnicos.
- **Destaque Técnico**: Introdução do `inspetor_regras.py` com Regex estrito e mecanismo de interrupção por exceção fatal (Fail-Fast).
- **Dossiês Envolvidos**: **Dossiê 16: Motor de Blindagem**.

---

## 6. Gatilhos de Protocolo (Protocol Routing)

Para garantir a soberania do contexto e a segurança das decisões críticas, a IDE deve carregar e aplicar os protocolos da pasta `/docs/protocolos/` conforme os gatilhos abaixo:

### 6.1 Protocolo P-11: Governança e Risco
**Sempre que:**
- For gerar código que manipule dados sensíveis de banco de dados (Oracle).
- Estiver em uma fase de planejamento de arquitetura (Mode: PLANNING).
- Lidar com regras de integridade de metadados clínicos.

### 6.2 Protocolo VT-3: Validação Tripla
**Sempre que:**
- For concluir uma tarefa de implementação (Mode: VERIFICATION).
- Estiver validando uma conversão de layout ou modificação de AST.
- Gerar artefatos de saída (JSON/XML) para produção ou teste.

> [!IMPORTANT]
> A leitura e aplicação destes protocolos é obrigatória antes de tomar decisões de design que afetem a integridade do ecossistema.

---

## 7. Governança e Manutenção

A base de conhecimento descrita na pasta `/docs/` é absoluta. Nenhum script ou código deve contradizer os princípios de integridade documentados. Se uma nova descoberta de engenharia reversa for feita, primeiro atualiza-se a prosa nos dossiês e, somente após a validação do conhecimento, o código correspondente deve ser alterado.
