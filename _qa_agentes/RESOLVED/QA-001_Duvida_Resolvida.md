# QUESTION_ID: [QA-001]

## Contexto
Durante o mapeamento da Rosetta Stone no Passo 2 da inicialização, identifiquei uma possível ambiguidade nos IDs de propriedade.

## Problema Encontrado (Referência: _base_de_dados)
No arquivo `dicionario_de_dados.md`, o ID 2 e o ID 52 parecem referenciar a "Lista de Valores" em contextos diferentes. O motor de hash original pode se comportar de forma distinta para cada um.

## Anomalia Observada
Não está claro se o sistema Réplica deve tratar ambos como `lista_valores` no JSON ou se devemos criar subtipos (ex: `lista_opcoes_estaticas` vs `lista_query_dinamica`).

## Propostas de Solução
1. **Unificação**: Tratar ambos como `lista_valores` e delegar ao motor a interpretação do conteúdo.
2. **Explicitação**: Mapear ID 2 como `lista_estatica` e ID 52 como `lista_dinamica`.

## Decisão Humana (HITL)
Decisão Com base nas Fontes
Correção do Contexto Forense: A premissa de que a ambiguidade envolve o ID 52 está incorreta de acordo com o mapeamento estrutural. A documentação mestre confirma que os IDs numéricos legados (CD_PROPRIEDADE) estendem-se estritamente do ID 1 ao 43. A verdadeira ambiguidade histórica em relação à "Lista de Valores" ocorre entre o ID 2 e o ID 25.
Decisão Arquitetural: A solução a ser adotada é a Unificação (Proposta 1 ajustada). O sistema deve tratar a propriedade estritamente como lista_valores (ou listaValores) do tipo Array, sem inventar subtipos arbitrários que o motor do Editor 3 não reconhecerá.
Diretrizes Estritas de Implementação (O "GAP FIX"):
1. Unificação do Legado (ID 2 e ID 25): O ID 25 é catalogado como um "legado ontológico e alternativo", que foi frequentemente intercambiado com o ID 2 durante o ciclo de vida do sistema antigo. Ambos devem convergir para a chave JSON moderna correspondente.
2. Reestruturação Topológica Obrigatória (Tokenização): Não basta apenas renomear a chave. No Editor 2 (XML), a lista de valores era uma string unidimensional onde as opções eram separadas por delimitadores como pipes (ex: OPCAO1|Valor1;OPCAO2|Valor2 ou SIM|S). A IDE Réplica (Antigravity) deve possuir um tokenizador embutido para converter essa string em um vetor multidimensional complexo (JSON Array) de objetos de valor.
3. Anatomia do Array de Valores: O JSON moderno exige que o array de lista de valores instancie múltiplos objetos independentes no nó fieldValues, cada um contendo campos atômicos: id (chave transacional), value (o dado puro), selected (booleano indicando seleção, nativamente false) e order (hierarquia direcional). Exemplo obrigatório de saída: [{"value": "teste", "selected": false, "order": 1}].
4. Separação de Listas Dinâmicas (Queries/APIs): A distinção entre opções estáticas e lógicas dinâmicas não se faz dividindo a "lista de valores". Lógicas dinâmicas e queries de banco de dados pertencem, por regra de arquitetura, às propriedades de ação: ID 4 (acao), ID 21 (acaoSql - blindada contra injeções) e ID 36 (requisicao_api - para serviços interoperáveis). O atributo lista_valores destina-se exclusivamente a conjuntos de opções pré-definidas
