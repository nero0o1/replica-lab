# 07 - EVENTOS E CALLBACKS: CICLO DE VIDA E INTERAÇÕES

Este dossiê descreve o motor de eventos (Event Loop) das réplicas, garantindo paridade com a execução síncrona/assíncrona do sistema MV.

## 1. O Pipeline de Eventos SINC-2Ψ
A execução de regras na web deve seguir uma ordem estritamente hierárquica para evitar discrepâncias de estado.

1.  **DOMContentLoaded**: Gatilho inicial.
2.  **StateOrchestrator.init()**: Registro de dependências e snapshots iniciais.
3.  **ON_LOAD Execution**: Disparo de regras de inicialização.
4.  **Idle Interface**: Aguardando entrada do usuário (`Interaction Layer`).

## 2. Tipologia de Gatilhos (Triggers)
Diferenciamos eventos de interface de eventos de motor:

| Gatilho | Mapeamento Original | Comportamento Web |
| :--- | :--- | :--- |
| `ON_CHANGE` | ruleType 1 | Evento `change` nativo + `update()` do orchestrator. |
| `IS_CLICK` | ruleOperator "is clicked"| Evento `click` (específico para botões/checks). |
| `ON_BLUR` | - | Validação pesada (prevista para Phase 2). |

## 3. Gestão de Reentrância (Stack Tracking)
A descoberta forense **Shadow Loop Reentrancy** revelou que o sistema MV permite que alterações no Campo A disparem o Campo B, que por sua vez pode redisparar o Campo A.

### Solução de Engenharia: The Active Set Guard
Para mimetizar este comportamento sem travar o navegador:
- Utilizamos um `Set` chamado `activeNodes`.
- Um `triggerId` é adicionado ao set no início do processamento e removido no `finally`.
- Tentativas de reentrada no mesmo `triggerId` enquanto ele está no set são ignoradas (Cycle Breaking).

## 4. Callbacks e Intent Union
Quando múltiplos eventos convergem para o mesmo alvo, o sistema aplica uma **União Determinística**. Se a Regra 1 e a Regra 2 afetam o `Campo_X`, o estado final é consolidado avaliando ambas. Se houver conflito (ex: Regra 1 pede DISABLE e Regra 2 pede ENABLE), a regra de maior restrição (Clinical Safety Priority) prevalece.
