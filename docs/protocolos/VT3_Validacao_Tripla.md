# Protocolo VT-3: Validação Tripla de Integridade

O protocolo VT-3 é mandatário para todas as saídas geradas que impactem o comportamento do sistema ou a estrutura de dados. Nenhuma alteração de nível N2 ou N3 pode ser considerada concluída sem a aplicação deste checklist.

## 1. Dimensões de Validação

### V1: Validação Lógica (Estrutura e AST)
- A saída é sintaticamente correta (JSON/XML/Código)?
- A estrutura AST mimetiza fielmente o comportamento esperado pelo backend MV?
- Há colisões de IDs ou identificadores duplicados?

### V2: Validação Factual (Conformidade com a Fonte)
- Os valores de metadados (IDs, Tipos) correspondem ao Dicionário de Dados?
- As descobertas de "Matéria Escura" (Oracle Shadow Logic) foram respeitadas?
- O comportamento é 1:1 com o Golden Master (se disponível)?

### V3: Validação Semântica (Intenção e Segurança)
- A intenção original do desenvolvedor/médico foi preservada?
- Existem riscos de segurança clínica (ex: ocultação acidental de campos obrigatórios)?
- A sanitização de inputs SQL foi aplicada?

## 2. Decisão e Status

Com base na aplicação do VT-3, o agente deve classificar seu trabalho em:

- **[PASS]**: Atende a todos os critérios. Pronto para entrega.
- **[REWRITE]**: Falha em um ou mais critérios, mas é corrigível em um novo ciclo de pensamento.
- **[BLOCK]**: Violação crítica de segurança ou regra inegociável. Requer intervenção humana ou parada imediata.

> [!IMPORTANT]
> Toda resposta técnica de alto nível deve vir acompanhada do selo `VT-3 VALIDATED` ou uma explicação de qual critério falhou.
