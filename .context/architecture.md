# ARCHITECTURE RULES & BOUNDARIES

Este documento define os limites técnicos e padrões de desenvolvimento para manter a sanidade do projeto.

## 1. Fronteiras de Responsabilidade

- **CORE (`src/core/`):** Deve ser agnóstico em relação ao formato de arquivo (não lê XML nem JSON diretamente). Trabalha apenas com objetos Python/AST.
- **IMPORTERS (`src/importers/`):** Única camada autorizada a fazer o parse de formatos externos. Deve produzir uma `MvDocument` (AST) válida.
- **EMITTERS (`src/emitters/`):** Única camada autorizada a gerar strings de saída. Deve receber uma AST e serializá-la.
- **CLI (`src/cli/`):** Camada de orquestração. Não deve conter lógica de negócio pesada, apenas configurar os pipes de importação/emissão.

## 2. Padrões de Nomenclatura

- **Classes:** `PascalCase` com prefixo `Mv` (ex: `MvField`).
- **Funções/Métodos:** `snake_case`.
- **Identificadores JSON:** Devem seguir o `camelCase` padrão da API do Editor 3.
- **Identificadores AST:** Preferencialmente `snake_case` para consistência interna.

## 3. Regra de Manutenção (Self-Healing)

Toda nova descoberta de engenharia reversa **DEVE** resultar em:
1.  Atualização de um dos arquivos em `/docs/knowledge_base/`.
2.  Refletir a mudança na AST se necessário.
3.  Jamais implementar lógica de "atalho" que pule a validação de Hash ou o TypeCaster.
