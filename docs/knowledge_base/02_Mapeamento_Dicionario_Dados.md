# 02 - MAPEAMENTO E DICIONÁRIO DE DADOS: O TRANSPLANTE LEGADO-MODERNO

Este manual detalha a tradução semântica necessária para converter a base racional do Editor 2 (baseada em IDs numéricos e tabelas Oracle) para a estrutura moderna do Editor 3 (baseada em JSON tipado). O entendimento deste mapeamento é o que permite ao nosso transpiler "falar" as duas línguas simultaneamente.

## 1. O Desafio da Evolução de Dados

O sistema MV original foi concebido em uma era onde a performance do banco de dados era ditada pela economia de caracteres. Por isso, em vez de propriedades descritivas, temos IDs numéricos opacos (ex: ID 7 é "Editável"). No sistema moderno (Editor 3), buscamos legibilidade. O nosso componente **TypeCaster** atua como o tradutor simultâneo nesse processo, garantindo que o que o Oracle chama de `7` seja corretamente compreendido pelo navegador como `editable`.

---

## 2. Dicionário Definitivo de Propriedades (IDs 1 a 52)

Abaixo, explicamos o significado clínico e técnico das propriedades mais frequentes encontradas na tabela `CD_PROPRIEDADE`. A correta interpretação desses campos define se o formulário será apenas um texto morto ou uma ferramenta clínica funcional.

### 2.1 Propriedades de Estrutura e Layout
- **ID 1 (Tamanho):** Define o limite de caracteres que o usuário pode digitar. No banco Oracle original, isso reflete o tamanho da coluna correspondente (VARCHAR). Se ignorarmos este ID, os dados inseridos pelo médico podem ser truncados ou causar erros de banco de dados por exceder o limite físico.
- **ID 3 (Máscara):** Controla o padrão visual (ex: Máscara de CPF ou Data). Sem este mapeamento, o usuário perderia a orientação visual necessária para preencher documentos padronizados.

### 2.2 Propriedades de Comportamento e Validação
- **ID 4 (Ação):** Esta é a propriedade mais poderosa. Ela armazena o "Motor do Campo" — muitas vezes uma query SQL complexa que preenche combos dinamicamente ou valida se uma dose de medicamento está correta.
- **ID 7 (Editável) e ID 8 (Obrigatório):** Estes são os guardiões da integridade clínica. Um campo obrigatório não preenchido impede a assinatura do prontuário. O mapeamento aqui exige a conversão de `'S'`/`'N'` para Booleanos reais em JSON.
- **ID 17 (Reprocessar):** Indica que qualquer alteração neste campo deve forçar a recalculação de todas as outras regras do formulário. É o gatilho da reatividade.

---

## 3. A Diferença de Paradigmas: XML contra JSON

Mapear dados entre o Editor 2 e o Editor 3 exige compreender as diferenças profundas de como a informação é organizada fisicamente.

### 3.1 A Estrutura Hierárquica no XML (Editor 2)
No sistema antigo, a informação é "aninhada". Se um campo pertence a um grupo, ele está fisicamente dentro da tag desse grupo no arquivo XML. O parser deve navegar por essa hierarquia buscando as tags `<property>` para reconstruir o objeto original.

### 3.2 A Estrutura de Objetos no JSON (Editor 3)
Já no Editor 3, as propriedades são chaves de um objeto JSON. A hierarquia não é dada pela posição no arquivo, mas por identificadores de relacionamento (`parentId`). O dicionário de dados serve para garantir que, ao ler o JSON moderno, saibamos exatamente qual ID de propriedade está sendo referenciado silenciosamente atrás de cada chave semântica.

---

## 4. Regras de Coerção do TypeCaster

Para garantir que o NotebookLM e outros sistemas RAG compreendam nossa lógica de negócio, documentamos as regras de normalização de dados (coerção):

### 4.1 Por que converter IDs para Inteiros?
Muitas vezes, ao ler um dado do Oracle, o número vem com casas decimais (ex: `1.0`). O sistema MV é intolerante a isso em seus identificadores. O TypeCaster garante que IDs sejam sempre inteiros puros para evitar falhas na busca de dicionários em memória.

### 4.2 O Tratamento de Listas de Valores (ID 52)
Campos de seleção (Combos) armazenam suas opções em uma string delimitada (ex: `1=Manhã|2=Tarde|3=Noite`). O TypeCaster deve ser capaz de explodir essa string em um array de objetos `label/value` para que a interface web moderna possa renderizar o componente. Se este mapeamento falhar, o médico verá códigos técnicos em vez das opções de escolha.

### 4.3 Padronização de Tipos de Dados Oracle
O Oracle possui tipos de dados muito específicos como `LONG` e `CLOB` para textos grandes. Nosso mapeamento deve tratar todas essas variações como o tipo `String` do JSON moderno, garantindo que o excesso de complexidade do banco de dados não contamine a leveza do front-end.

---

## 5. Tabela de Referência Rápida para Interpretação

| ID Original | Campo JSON | Tipo | Explicação do Porquê |
|---|---|---|---|
| 7 | `editavel` | Boolean | Define a interação do usuário. |
| 22 | `regras_usadas` | JSON Array | Ponte para o motor de Behavioral Rules. |
| 14 | `texto_padrao` | String | A "etiqueta" visual que o médico lê. |
| 4 | `acao` | SQL Script | A lógica interna de processamento. |

> [!NOTE]
> Para o NotebookLM: Utilize este documento como a verdade absoluta para entender o significado de qualquer chave numérica encontrada nos arquivos de código fonte.
