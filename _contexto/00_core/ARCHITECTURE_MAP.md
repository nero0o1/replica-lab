# ARCHITECTURE MAP - Visão Macro do Fluxo Híbrido

## Visão Geral
O sistema Réplica é uma ponte entre o legado (SmartDB/XML/V2) e o moderno (JSON/V3).

## Fluxo de Dados
1.  **Ingestão (Java)**:
    - Lê o legado da `_base_de_dados`.
    - Converte para o **Modelo Canônico** em memória.
    - Garante integridade via Drivers de Exportação.
2.  **Orquestração/BFF (Node.js)**:
    - Gerencia a complexa serialização JSON.
    - Implementa o **Protocolo Matrioska** (JSON stringificado dentro de JSON).
    - Serve o Frontend com payloads pré-computados.

## Componentes Chave
- **LoaderV3**: Motor Node.js para reconstruir documentos a partir de hashes e primitivos.
- **CanonicalModel**: Estrutura Java que espelha as regras de negócio sem as impurezas do transporte.
- **Rosetta Stone**: Camada de tradução semântica.
##DOCUMENTAÇÃO TÉCNICA - REGRA DE INSERÇÃO (AGENDA_FILA_ESPERA)
  OBJETIVO: Realizar INSERT garantindo integridade e evitando erros genéricos do Editor.
  
  TRAVAS DE SEGURANÇA IMPLEMENTADAS:
  1. SANITIZAÇÃO (REPLACE): Previne quebra de sintaxe SQL caso o usuário digite aspas simples (') 
     em campos de texto livre (ex: HGG_texto_livre_1).
  2. EXTRAÇÃO NUMÉRICA (REGEXP_SUBSTR): Garante que apenas o ID seja enviado para colunas 
     NUMBER, ignorando a descrição em campos ComboBox (ex: '3||TOMOGRAFIA' -> 3).
  3. CONTROLE DE PRECISÃO (SUBSTR): Limita o tamanho de strings enviadas para colunas de 
     precisão fixa, como CD_SER_DIS (NUMBER 4,0).
  4. TRATAMENTO DE NULOS (NVL): Assegura o preenchimento de colunas mandatórias (CD_CONVENIO, 
     CD_CON_PLA) mesmo em atendimentos com cadastro incompleto.