# 14 - AUDITORIA VT3 E SOBERANIA DE DADOS

Este dossiê define os protocolos finais de validação que garantem a soberania dos dados durante as operações de transporte e modificação de formulários.

## 1. O Protocolo VT-3 (Validação Tripla)

A conformidade VT-3 é o padrão "Gold Master" de integridade no projeto Réplica MV. Ela exige que um documento passe por três barreiras de validação:

### Barreira 1: Integridade Estrutural (Schema)
- O arquivo de saída (XML ou JSON) deve ser validável sintaticamente.
- Tags mandatórias (CD_DOCUMENTO, NM_IDENTIFICADOR) devem estar presentes.

### Barreira 2: Integridade Semântica (Behavioral)
- Lógicas compostas `(A AND B) OR C` devem resultar na mesma árvore AST na ida e na volta.
- Prefixos de campos (`TXT_`, `CMB_`) devem ser preservados 1:1.

### Barreira 3: Integridade Criptográfica (Security)
- O `version.hash` (MD5) deve ser recalculado e validado.
- Nenhum bit de dado clínico pode ser alterado sem a atualização correspondente da assinatura de integridade.

## 2. Auditoria de Overflow e Constraints RDBMS

O utilitário `reconstruction_audit.py` atua como o fiscal desta soberania. Ele impede que modificações programáticas quebrem as leis físicas do banco de dados:
- **Hard Limit**: Bloqueia qualquer tentativa de salvar strings > 4000 caracteres em campos Oracle VARCHAR2.
- **Boundary Check**: Garante que nenhum componente seja movido para fora das coordenadas visíveis do layout (X/Y negativos).

## 3. Soberania da "Matéria Escura" (Vault Preservation)

O binário `LO_REL_COMPILADO` (Jasper) é considerado o cofre sacrossanto do documento.
- **Regra de Ouro**: Se o transpiler encontrar um Jasper blob que ele não consegue decodificar plenamente, ele deve aplicar o protocolo de **Reinjeção de Fallback**.
- **Resultado**: O documento continua funcional e visualmente idêntico no Editor 2 legado, mesmo após ter sido editado por ferramentas externas.

## 4. Glossário de Soberania (Clinical Naming)

Para garantir que a tecnologia não oculte o propósito clínico, utilizamos nomes funcionais nos logs de auditoria:
- `IntegrityCheckpoint` ➔ Propriedade 8 (Obrigatório).
- `ClinicalLock` ➔ Propriedade 17 (Editável).
- `ContextSovereignty` ➔ Preservação de tags `&<PAR_...>`.

> [!IMPORTANT]
> A falha em qualquer um dos critérios da Auditoria VT-3 inviabiliza o uso do documento em ambiente de produção (MV Soul/PEP).
