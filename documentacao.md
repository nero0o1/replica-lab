# Documentação Técnica: Onda 1 - O Esqueleto da Máquina

Esta documentação detalha a implementação da **Onda 1**, estabelecendo a fundação estrutural do sistema Réplica MV.

## 1. Mapeamento Arquitetural (Visão Geral)

O sistema Réplica MV é organizado para garantir a interoperabilidade entre os editores legado (V2) e moderno (V3). A estrutura de diretórios atual é a seguinte:

- **src/core/**: Motor principal, contendo os modelos canônicos (`ast_nodes.py`, `CanonicalModel.ps1`) e lógica de serialização (`json_serializer.py`).
- **src/importers/**: Módulos para ingestão de metadados legados.
- **src/emitters/**: Módulos para geração de saídas modernas (Web/JSON).
- **onda1_skeleton/**: Repositório dos artefatos da fundação estrutural.
- **docs/**: Dossiês de conhecimento técnico e segurança.

## 2. Especificação da Onda 1 (JSON Foundation)

A fundação é baseada em um arquivo JSON estritamente ordenado, concebido como um sistema de 'gavetas etiquetadas'. Cada chave possui um propósito específico para garantir o alinhamento sistêmico.

### Ordem das Chaves e Propósitos:

1.  **Nome**: Rótulo legível do artefato ou template.
2.  **Identificador**: ID único e constante para referenciamento interno.
3.  **Tipo**: Classificação do artefato (ex: `ESTRUTURA_BASE`, `TEMPLATE_FORM`).
4.  **Grupo**: Agrupamento lógico para controle de permissões e contexto.
5.  **Dados**: Objeto contendo os metadados brutos e carga útil do sistema.
6.  **Versão**: Controle de versão semântica do esqueleto.
7.  **Layout**: Definições espaciais e de renderização (física do formulário).

## 3. Log de Auditoria (Passo 3)

Os seguintes arquivos foram atualizados para reconhecer e interagir com a nova fundação da Onda 1:

| Arquivo | Alteração Realizada |
| :--- | :--- |
| `src/core/ast_nodes.py` | Adicionada classe `Onda1Foundation` com suporte a `OrderedDict` para exportação JSON estrita. |
| `src/core/json_serializer.py` | Adicionado método `serialize_wave1` para garantir a ordem das chaves na persistência do arquivo. |
| `src/core/CanonicalModel.ps1` | Implementada classe `MvFoundation` em PowerShell com suporte a `[ordered]` hash para paridade sistêmica. |
| `onda1_skeleton/skeleton_base.json` | Criação do arquivo físico da fundação utilizando a ordem obrigatória. |

---
*Assinado: Agente Arquiteto de Software Autônomo.*
