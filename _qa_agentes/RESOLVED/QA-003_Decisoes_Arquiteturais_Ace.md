# PENDING_QUESTIONS: Lacunas de Sincronização ACE [V2]

Este documento lista as novas dúvidas surgidas durante o preenchimento exaustivo dos Playbooks Técnicos baseados no Oráculo.

## 1. Dúvidas de Engenharia de Domínio (Java)
- **[Q-09] Colisões de IDs Negativos**: Em um cenário de trabalho multi-usuário (vários médicos editando formulários em rascunho), qual a faixa de IDs negativos reservada para evitar colisões antes da sincronização com a `SEQ_MAP_EDITOR_MV`?
- **[Q-10] Vault Integrity**: Caso o binário Jasper (`LO_REL_COMPILADO`) lido no Oráculo esteja corrompido ou com formato não suportado pela versão local do Java, o sistema deve impedir o salvamento (VT-3 Fail) ou permitir o salvamento marcando o Jasper como "Broken"?
- **[Q-11] Oracle CLOB Limits**: Embora o VARCHAR2 tenha o limite de 4000 caracteres, o CLOB para `acaoSql` permite volumes maiores. Devemos aplicar algum limite de performance (ex: 2MB) no transporte dessas lógicas para o BFF?

## 2. Dúvidas de Orquestração (Node/React)
- **[Q-12] Union Logic Conflict**: No documento 07, é citado que a "prioridade de maior restrição" prevalece. Existe uma tabela de precedência oficial? (Ex: DISABLE sempre vence ENABLE? HIDE sempre vence SHOW?).
- **[Q-13] State Snapshot Storage**: O `data-initial-state` deve ser armazenado como um atributo no DOM (visível no Inspecionar Elemento) ou deve ser mantido em um Store de memória privado do React/StateOrchestrator para evitar manipulação do usuário?
- **[Q-14] Base64 Encoding Overhead**: Para documentos muito grandes com muitas imagens (Blobs), o custo do Base64 no JSON Matrioska pode causar lentidão no parse Java. Há autorização para implementar compressão GZIP antes da codificação Base64?

## 3. Dúvidas de UI/UX
- **[Q-15] Mobile Geometry**: Ao carregar um layout de pixels absolutos (Editor 2) em um dispositivo móvel, o sistema deve forçar o scroll horizontal (Modo Desktop) ou deve tentar uma escala proporcional (Zoom-out)?
- **[Q-16] Font Scaling**: Se a fonte MS Sans Serif (clássica) não estiver presente no sistema operacional do cliente, qual a fonte de fallback autorizada que mantém a mesma métrica de largura de caracteres para evitar que o texto transborde o campo?

---
*Assinado: Especialista em Contexto Agêntic (ACE)*
1. Dúvidas de Engenharia de Domínio (Java)
• [Q-09] Colisões de IDs Negativos: As fontes fornecidas não fazem menção à tabela SEQ_MAP_EDITOR_MV e não especificam nenhuma faixa de IDs negativos a ser reservada para evitar colisões no modo multi-usuário ou de rascunhos.
• [Q-10] Vault Integrity: O comportamento prescrito pelas fontes para o caso do binário Jasper (LO_REL_COMPILADO, identificado pelo Magic Number ACED0005) estar corrompido ou falhar na extração é o bloqueio. A especificação de erro determina que se o ACED0005 for encontrado, mas nenhum payload XML for extraído (o que ocorre se estiver corrompido ou ilegível), o sistema deve emitir um erro crítico e impeditivo: [FAIL] Java Breaker Protocol Violation. Não há menção ou autorização para contornar isso marcando o documento como "Broken".
• [Q-11] Oracle CLOB Limits: Embora a documentação detalhe que a acaoSql necessita de achatamento contínuo (flattening) e escape rigoroso, e mencione que a técnica de stringificação em layouts.content foi adotada justamente para lidar com o armazenamento via CLOB/TEXT no Oracle, as fontes não estabelecem nenhum limite de transporte de rede (ex: 2MB) em nível de BFF para essas lógicas.
2. Dúvidas de Orquestração (Node/React)
• [Q-12] Union Logic Conflict: As fontes não apresentam nenhuma tabela de precedência oficial sobre a "prioridade de maior restrição" (ex: conflitos entre regras DISABLE e ENABLE).
• [Q-13] State Snapshot Storage: As fontes não abordam a variável data-initial-state ou regras específicas de armazenamento de snapshot (DOM vs. Store privado em React/StateOrchestrator).
• [Q-14] Base64 Encoding Overhead: As fontes não autorizam a implementação de compressão GZIP. Pelo contrário, as regras da arquitetura e as premissas do sistema ditam rigidamente que as imagens em Base64 e os blocos de segurança embutidos (c2pa/jumbf) são considerados "conteúdos opacos". O exportador e o importador devem garantir um transporte de "round-trip bit-a-bit" sem aplicar reformatadores ou limpezas, o que invalida qualquer camada de compressão arbitrária não reconhecida nativamente pelo interpretador legado.
3. Dúvidas de UI/UX
• [Q-15] Mobile Geometry: A documentação técnica confirma que o Editor 2 usava um "grid rígido" incompatível com layouts responsivos complexos e que a renderização depende de coordenadas espaciais absolutas X/Y. No entanto, não há instruções na documentação sobre qual deve ser o comportamento (scroll horizontal forçado ou escala proporcional) ao carregar a geometria no mobile.
• [Q-16] Font Scaling: Não existe nas fontes nenhuma regra sobre fontes de fallback autorizadas para substituir a MS Sans Serif e manter as métricas de largura; os documentos JSON contidos nos exemplos utilizam primariamente propriedades que invocam fontes web padrão, como "Arial" ou "Verdana".