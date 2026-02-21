# 12 - SEGURANÇA, AUTORIZAÇÃO E QUARENTENA

Este dossiê define a barreira de defesa (Safety Guardrails) do Réplica MV, focando em integridade clínica e prevenção de execução de código malicioso.

## 1. O Protocolo de Quarentena Inerte (SEC-1)
Uma das descobertas mais críticas da fase de engenharia reversa foi a presença de "Matéria Escura" em scripts Oracle (`OPAQUE_SQL`). Esses scripts podem conter lógicas de negócio vitais que não podem ser traduzidas automaticamente para JS sem risco clínico.

### 1.1 Implementação via Base64
Para evitar que o interpretador do navegador execute ou falhe ao encontrar caracteres especiais do PL/SQL (como `*/` ou `&`), o sistema aplica uma **Quarentena Inerte**:
- O código é codificado em **Base64**.
- É injetado em uma tag `<script>` com MIME-type `application/vnd.mv.quarantine`.
- O navegador trata o conteúdo como texto bruto, impedindo qualquer execução acidental (XSS Zero-Day Prevention).

## 2. Controle de Acesso e "Read-Only" Enforcement
Quando um componente entra em quarentena ou falha na validação de hash:
- **Atributo**: `data-quarantined="true"`.
- **Efeito**: O campo é forçado em modo `disabled` (Read-Only) deterministicamente.
- **Log**: A anomalia é registrada no `execution_ledger.json` para auditoria forense posterior.

## 3. Sandboxing de Execução
O uso de quarentena permite que as equipes de TI dos hospitais revisem o código original antes de uma migração definitiva. O Réplica Editor atua como um visualizador seguro, garantindo que o formulário possa ser preenchido parcialmente enquanto as lógicas complexas são migradas manualmente para novos microserviços.

## 4. Proteção contra PII (Patient Identifiable Information)
Conforme o **Dossiê 09**, o sistema deve mascarar ou resolver variáveis de sessão contendo dados de pacientes antes da ejeção. O Emitter aplica uma política de **Context Masking**, onde `PAR_CD_PACIENTE` é tratado como um token opaco na interface do usuário.
