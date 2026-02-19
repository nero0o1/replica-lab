# 04 - Guia de Reconstrução Lógica

Autor: Agente Antigravity (via NotebookLM)
Data: 2026-02-18

## A História da Construção (Reverse Engineering)
Este documento narra a ordem lógica em que as peças foram criadas, servindo como guia para entender a evolução do código.

### Passo 1: O Mistério do Hash (Reverse Engineering)
- **Problema**: Arquivos JSON editados manualmente eram rejeitados pelo sistema (`VERSION_HASH_MISSING`).
- **Ação**: Criação de scripts de experimento (`experiment_version_hash_v*.ps1`).
- **Descoberta**: Comparando arquivos válidos, descobriu-se que o hash depende exclusivamente do objeto `data` serializado de forma minificada. O `DriverV3` implementa essa lógica.

### Passo 2: A Necessidade do Híbrido (Architecture Pivot)
- **Problema**: O projeto focava apenas no JSON moderno, mas o legado XML ainda era necessário.
- **Solução**: Design da arquitetura "Canonical Core" para servir dois senhores.
- **Artefato**: Criação de `CanonicalModel` e `RosettaStone` para abstrair as diferenças.

### Passo 3: Implementação dos Drivers
- **Ação**:
  1. **Driver V3**: Prioritário. Implementou-se a exportação JSON com a lógica de hash descoberta no Passo 1.
  2. **Driver V2**: Secundário. Implementou-se a exportação XML com lógica de degradação (converter Arrays modernos em Strings legadas para não quebrar tabelas antigas).

### Passo 4: Verificação Circular (Round-Trip)
- **Ação Final**: Criação do `LoaderV3` e do teste `test_roundtrip.ps1`.
- **Prova de Sucesso**: O sistema consegue ler um arquivo, converter para memória, e gerar um novo arquivo cujo Hash é idêntico ao original.

## Pontos de Atenção (Dívida Técnica)
1. **MD5**: O uso de MD5 é imposto pelo legado, mas deve ser observado.
2. **Rosetta Stone Estática**: O dicionário de IDs está "chumbado" no código (`src/Core/RosettaStone.ps1`). Para suportar novos componentes MV no futuro, este arquivo precisará ser editado.
3. **Parseamento de XML**: O projeto atual gera XML (Driver V2) mas ainda não possui um `LoaderV2` para ler XML legado. A migração é atualmente unidirecional (Moderno -> Import -> Export Híbrido).
