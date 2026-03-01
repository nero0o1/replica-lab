# NÚCLEO DE DESENVOLVIMENTO E PLANO DE IMPLEMENTAÇÃO - PROJETO RÉPLICA

Este documento consolida o conhecimento da base de dados e define a rota para o desenvolvimento da nova aplicação utilizando **Java** e **Node.js**.

---

## 1. O Núcleo do Conhecimento (Base de Dados)

O "Cérebro" do projeto está mapeado no diretório `/_base_de_dados`. Abaixo estão os pilares fundamentais extraídos da base Oracle e do ecossistema legado:

### 1.1 Integridade Forense (O Cadeado MD5)
*   **Hash de Raiz:** Composto por `ID_INTERNO + IDENTIFICADOR_TECNICO + TIPO_UI`.
*   **Hash de Propriedade:** Cada atributo (editabilidade, visibilidade, etc.) possui sua própria assinatura.
*   **Regras de Ouro:**
    *   Tratamento de `null` (não gera hash).
    *   Booleans em strings minúsculas (`"true"`/`"false"`).
    *   Sanitização de quebras de linha (`\n` apenas).

### 1.2 Dicionário Semântico (Mapping 1-52)
*   Tradução de IDs numéricos opacos para chaves legíveis (ex: ID 7 -> `editavel`).
*   **TypeCaster:** Sistema de coerção de tipos para garantir que o Oracle (Float/String) se comporte corretamente no JSON moderno.

### 1.3 Motor Comportamental (Regras de Negócio)
*   **Propriedade 4 (Ação):** Scripts SQL e lógicas clínicas que ditam o comportamento do formulário.
*   **Propriedade 17 (Reprocessar):** O gatilho de reatividade do sistema.

---

## 2. Objetivo Atual: Transição para Java e Node.js

O próximo grande passo é a **migração do motor de translação (Transpiler)** de Python para uma infraestrutura empresarial:

*   **Java (Backend/Core):** Responsável pelo processamento pesado de AST, cálculos de Hash de alta performance e integração direta com o banco de dados Oracle.
*   **Node.js (Frontend/Orquestração):** Responsável pela interface do "Editor Moderno", visualização Pixel-Perfect e API de middleware.

---

## 3. Plano de Desenvolvimento Inicial (Roadmap)

### Fase 1: Fundação Java (Mv-Core-Java)
1.  **Modelo de Dados:** Criar o POJO/Record para `MvDocument`, `MvField` e `MvProperty`.
2.  **Módulo de Criptografia:** Implementar o `HashEngine` em Java seguindo rigorosamente o Dossiê 01.
3.  **TypeCaster Service:** Portar a lógica de tradução de propriedades (Dossiê 02).

### Fase 2: Ecossistema Node.js (Replica-Bridge)
1.  **API REST/gRPC:** Criar o servidor Node que consome o motor Java.
2.  **Dashboard de Conversão:** Interface para gerenciar a translação de múltiplos arquivos `.edt` simultaneamente.
3.  **Visualizador de Layout:** Motor de renderização utilizando a Matriz de Z-Index.

### Fase 3: Validação VT-3
1.  **Teste de Paridade:** Garantir que o output do motor Java seja idêntico ao do motor legado (Round-Trip Test).
2.  **Auditória de Dados:** Verificação automática de integridade pós-conversão.

---

## 4. Próximos Passos (Ação Imediata)

Para iniciar o desenvolvimento hoje:
1.  **Inicializar o projeto Java (Maven/Gradle):** Estruturar os pacotes `com.mv.replica.core`.
2.  **Criar o ambiente Node.js:** `npm init` para o módulo de integração.
3.  **Mapear as dependências críticas:** JDBC para Oracle, Jackson para JSON, e bibliotecas de MD5.

> [!IMPORTANT]
> A base de conhecimento em `/docs/knowledge_base/` deve ser consultada a cada nova classe implementada para evitar quebras no sistema de segurança clínica.
