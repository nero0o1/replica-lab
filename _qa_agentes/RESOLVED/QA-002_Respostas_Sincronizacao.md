# PENDING_QUESTIONS: Sincronização de Informações Omissas

Este documento lista as lacunas de informação identificadas durante a populagem da "Memória RAM" e do "Oráculo". Para cada pergunta, é necessário uma decisão ou fornecimento de dado adicional para garantir a integridade do sistema Réplica.

## 1. Dúvidas de Regra de Negócio e Domínio Clínica
- **[Q-01] Persistência de Booleano**: No Oráculo, vemos 'S'/'N'. No Playbook, definimos `true`/`false`. Ao salvar de volta para o banco legado via Java, o motor deve converter automaticamente para 'S'/'N' ou existe algum caso onde o booleano JSON deve ser persistido como 0/1?
- **[Q-02] ID 2 vs ID 52**: Conforme levantado na QA-001, qual a regra definitiva para diferenciar listas estáticas (hardcoded no metadado) de listas dinâmicas (SQL FETCH)? O sistema deve tratá-las de forma unificada no `CanonicalModel`?
- **[Q-03] Prioridade de Trigger**: Existe algum cenário onde um `ON_CHANGE` (ID 17) não deva ser disparado mesmo se a flag estiver ativa? (Ex: durante um `FETCH_SQL` em lote).

## 2. Dúvidas de Arquitetura e Engenharia
- **[Q-04] Matrioska Escaping**: O motor Java legado espera as aspas duplas da string de layout escapadas com barra invertida (`\"`) ou as aspas devem ser substituídas por aspas simples durante o achatamento (flattening)?
- **[Q-05] Encoding de Blobs**: Para o componente `IMAGE`, os blobs do Oracle devem ser transmitidos via BFF como Base64 (Data URI) ou devemos implementar um endpoint de stream dedicado por ID de blob?
- **[Q-06] Sandbox de Quarentena**: Qual deve ser o comportamento do sistema quando um usuário tentar editar um campo em `data-quarantined="true"`? Devemos apenas mostrar o aviso ou bloquear totalmente o teclado (ReadOnly)?

## 3. Dúvidas de Infraestrutura
- **[Q-07] LocalPort e Serviços**: Quais portas locais o Java (Spring?) e o Node (Fastify?) utilizarão para comunicação entre si durante o desenvolvimento da réplica?
- **[Q-08] Versionamento de Layout**: Ao salvar um documento V3, o sistema deve sobrescrever a versão anterior ou devemos implementar um histórico de versões (`CD_DOCUMENTO_HISTORICO`) no banco Réplica?

---
1. Dúvidas de Regra de Negócio e Domínio Clínica
• [Q-01] Persistência de Booleano: O DriverV2 (Conversor Legacy) tem a responsabilidade de converter o dado booleano para S/N, true ou false, sempre obedecendo à regra específica de cada propriedade. Propriedades como obrigatorio e editavel devem usar true ou false (em letras minúsculas), enquanto propriedades como o SN_ATIVO devem usar S ou N. Não há menções nas fontes a respeito do uso de 0/1 para booleanos.
• [Q-02] ID 2 vs ID 52: Conforme o escopo do Dicionário de Dados, os IDs numéricos legados (CD_PROPRIEDADE) variam estritamente do ID 1 ao 43, de modo que o ID 52 não existe para definição de propriedades. As opções estáticas de um componente pertencem de forma unificada à propriedade lista_valores (derivada dos IDs 2 e 25), que deve ser tratada como um Array JSON de objetos. As lógicas de queries dinâmicas não devem ser misturadas nesta chave, pois devem ser mapeadas em propriedades exclusivas de ação: o ID 4 (acao), o ID 21 (acaoSql) ou o ID 36 (requisicao_api).
• [Q-03] Prioridade de Trigger: O ID numérico 17 refere-se à propriedade reprocessar (Reprocessar ação). Segundo as fontes, essa propriedade carrega uma diretiva mandatória para reciclagem assíncrona e deve ser invocada toda vez que ocorrerem mutações em variáveis macro no entorno hospitalar. As fontes não citam explicitamente nenhum cenário de exceção (como execuções em lote) em que ela não deva ser disparada se a flag estiver ativa.
2. Dúvidas de Arquitetura e Engenharia
• [Q-04] Matrioska Escaping: O nó layouts.content exige uma dupla serialização (Inception) onde o layout deve ser transformado em uma string monolítica com as aspas duplas preservadas e escapadas através de barras invertidas (\"). As aspas não devem ser substituídas por aspas simples. O formato serializado correto gerado pelo exportador é obrigatoriamente: "layouts": { "content": "{\"grid\":...}" }.
• [Q-05] Encoding de Blobs: Para o componente de imagem (IMAGE, ID V3: 10), o conteúdo é tratado diretamente em Base64. As imagens em Base64, juntamente com blocos de segurança (C2PA/JUMBF), devem ser classificadas como conteúdo opaco e preservadas bit a bit. O modelo não deve aplicar nenhuma limpeza global, formatação ou reconversão no momento em que trafega esses dados.
• [Q-06] Sandbox de Quarentena: As fontes não fazem qualquer menção a regras de negócio envolvendo data-quarantined="true" ou a uma "Sandbox de Quarentena". Você precisará definir o comportamento dessa funcionalidade fora da documentação oficial fornecida.
3. Dúvidas de Infraestrutura
• [Q-07] LocalPort e Serviços: As fontes não especificam as portas locais a serem utilizadas na arquitetura, nem possuem diretrizes ou menções sobre a utilização de frameworks como Spring ou Fastify.
• [Q-08] Versionamento de Layout: O sistema moderno trata o versionamento inserindo atributos na própria raiz do JSON V3, exigindo campos como "version" (recebendo um número inteiro, ex: 17) e "versionStatus" (indicando, por exemplo, "PUBLISHED"). O editor lida graficamente com uma área reservada onde são listadas as versões do documento (Teste e Publicada). Contudo, as fontes não detalham em nível de banco de dados se a persistência na réplica deve sobrescrever o registro principal ou povoar necessariamente uma tabela de histórico (CD_DOCUMENTO_HISTORICO). Essa decisão arquitetural na réplica deve ser alinhada com as necessidades do ecossistema alvo.
