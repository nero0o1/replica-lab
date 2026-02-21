# 06 - GERENCIAMENTO DE SESSÃO E VARIÁVEIS DE CONTEXTO (SINC-2Ψ)

Este dossiê detalha como o sistema lida com a volatilidade de dados e as variáveis de sessão herdadas do ecossistema Oracle/MV.

## 1. O Paradigma da Sessão Estática
Em ambientes web tradicionais, a sessão é mantida via cookies ou tokens. No Réplica MV, a "sessão" é injetada no documento AST no momento da transposição. Isso transforma variáveis voláteis em constantes protegidas durante a vida útil do formulário clínico.

## 2. Injeção de Macros de Contexto (SmartDB)
As variáveis identificadas como `&<PAR_...>` são tratadas como **Variáveis de Injeção de Primeiro Nível**.

| Macro | Significado Clínico | Tratamento no Emitter |
| :--- | :--- | :--- |
| `&<PAR_CD_ATENDIMENTO>` | ID do Atendimento Atual | Injetado como atributo `data-context-atend`. |
| `&<PAR_USUARIO_LOGADO>` | Login do Profissional | Injetado apenas para fins de LOG (Forensics). |
| `&<PAR_CD_PACIENTE>` | Identificador Único do Paciente | Chave de isolamento de segurança. |

## 3. Persistência de Estado (State Snapshot)
Para suportar a funcionalidade de "Reversão de Estado" (State Reversal), o `StateOrchestrator` mantém um snapshot do estado inicial disparado pelo `ON_LOAD`.

- **data-initial-state**: Atributo JSON embutido em cada tag `mv-field-` contendo `{disabled, visible, value}`.
- **Recalculo Determinístico**: Ao contrário de sistemas de "toggle", o estado da sessão web é recalculado a cada mudança, garantindo que o fecho de regras (Union Logic) seja respeitado.

## 4. Segurança do Contexto
> [!IMPORTANT]
> **Sanitização de Macros**: O `RuleLexer` substitui macros `&<...>` por tokens neutros `{{SYSTEM_VAR:...}}`. Isso impede que injeções de SQL maliciosas enviadas via parâmetros de URL sejam executadas pelo motor behavioral antes da validação.
