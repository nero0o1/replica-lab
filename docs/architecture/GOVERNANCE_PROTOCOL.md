# GOVERNANCE PROTOCOL: Institutional Order

Este protocolo define as leis de fronteira e os invariantes de dados necessários para manter a integridade do ecossistema MV Hybrid.

## 1. Fronteiras do Sistema (Layer Boundaries)

### 1.1 Core Layer (`src/Core`)
- **Responsabilidade**: Definição de Modelos e Rosetta Stone.
- **PROIBIÇÕES**:
    - Jamais importar logic de drivers (V2/V3).
    - Jamais realizar operações de IO (FileManager, Network).
    - Jamais conter chaves criptográficas voláteis.

### 1.2 Importer Layer (`src/Importers`)
- **Responsabilidade**: Engolir dados sujos e normalizar.
- **PROIBIÇÕES**:
    - Jamais exportar para arquivo diretamente.
    - Jamais bypassar o `Sanitize-Identifier`.

### 1.3 Driver Layer (`src/Drivers`)
- **Responsabilidade**: Garantir a fidelidade da saída (Serialization).
- **PROIBIÇÕES**:
    - Jamais alterar o estado do `MvDocument` original.
    - Jamais reduzir a precisão de decimais ou booleanos.

## 2. Invariantes de Dados (Inviolable Truths)

| Invariante | Descrição | Consequência da Quebra |
| :--- | :--- | :--- |
| **ID Persistence** | O `identifier` não pode mudar entre import/export. | Perda de bind em campos do PEP. |
| **Hash Stability** | MD5 de `true` deve ser sempre `b326...`. | [FATAL] Integridade Violada no Editor Moderno. |
| **No-Delete Rule** | Módulos obsoletos devem ser marcados, não deletados (`src/Legacy`). | Quebra de ferramentas de auditoria forense. |
| **SQL Rawness** | Variáveis SQL `&<...>` devem permanecer raw em JSON. | Scripts de decisão clínica param de funcionar. |

## 3. Escalabilidade e Governança
- **Adição de Novos Tipos**: Deve ser feita via `RosettaStone.ps1` primeiro, com validação de hash antes da liberação.
- **Audit Logging**: Todo desvio de hash deve ser logado explicitamente no processo de migração.

---
*Protocolo titan v2.0 - Vigilância Constante.*
