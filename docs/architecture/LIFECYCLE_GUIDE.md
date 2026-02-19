# LIFECYCLE GUIDE: Reconstruction & Deconstruction

Guia operacional para a manutenção da "Fonte da Verdade" no ecossistema MV Hybrid.

## 1. Como Reconstruir (Sync Protocol)
Sempre que houver alteração em `CanonicalModel` ou `RosettaStone`, siga este checklist:

1. **Extração de Anatomia**:
    - Execute `Get-Member` na classe alterada.
    - Atualize as tabelas de campos no `docs/architecture/DOCS_ANATOMY.md`.
2. **Atualização de Invariantes**:
    - Se o método de hashing mudar, o `GOVERNANCE_PROTOCOL.md` deve ser revisado imediatamente.
3. **Verificação de Regressão**:
    - Rode o `fire_test_v12_standalone.ps1`.
    - Se o teste de fogo passar, o novo estado é a nova "Verdade Absoluta".

## 2. Como Desconstruir (Safe Deprecation)
 Checklist para remover módulos ou campos depreciados:

- [ ] **Dependency Audit**: Procure por referências no `mass_migrator` e nos `DriversV2/V3`.
- [ ] **Mock Archiving**: Antes de deletar o arquivo, mova para `src/_archived/` sob o TITAN PROTOCOL.
- [ ] **Schema Update**: Remova a referência na `API_SPECIFICATION.md`.
- [ ] **Historical Link**: Adicione uma nota no `DATA_ANALYSIS_SUMMARY.md` explicando o porquê da remoção (ex: "ID X removido pois era metadado transiente irrelevante para o modern").

## 3. Script Mental para Mudanças de Schema
> "Se eu mudar um tipo de dado de String para Integer no Importer, eu quebro o MD5 do Driver? Se sim, a mudança deve ser acompanhada de uma atualização na Tabela de Hashes Estáticos?"

---
*Este guia deve ser lido por todo novo agente de IA introduzido no projeto.*
