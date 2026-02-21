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
│   └── knowledge_base/
│       ├── 01_Criptografia_e_Integridade.md   # MD5, Hashes e Validações.
│       ├── 02_Mapeamento_Dicionario_Dados.md  # Dicionário de IDs e Tipos.
│       ├── 03_Motor_Comportamental.md         # Regras Lógicas e Gatilhos.
│       ├── 04_Arquitetura_Transpiler.md       # AST e Mecanismos de Conversão.
│       └── 05_Catalogo_UI_e_Estilizacao.md    # Componentes e Design Pixel-Perfect.
├── src/                        # O Motor de Código
│   ├── core/                   # Lógica Pura (AST, Hash Engine).
│   ├── importers/              # Conversores de Entrada.
│   ├── emitters/               # Conversores de Saída.
│   └── cli/                    # Interfaces de Operação.
└── tests/                      # A Barreira de Qualidade
    ├── unit/                   # Testes de Componentes.
    └── integration/            # Testes de Ponta a Ponta.
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

---

## 4. Governança e Manutenção

A base de conhecimento descrita na pasta `/docs/` é absoluta. Nenhum script ou código deve contradizer os princípios de integridade documentados. Se uma nova descoberta de engenharia reversa for feita, primeiro atualiza-se a prosa nos dossiês e, somente após a validação do conhecimento, o código correspondente deve ser alterado.
