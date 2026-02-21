# 08 - INTERNACIONALIZAÇÃO E LOCALIZAÇÃO (I18N)

Este dossiê descreve a estratégia para suportar múltiplos idiomas e padrões regionais dentro do ecossistema de réplicas.

## 1. O Desafio das Strings "Hardcoded" do Oracle
No Editor 2, muitas mensagens de erro e labels são inseridas diretamente via PL/SQL ou propriedades estáticas.

## 2. Estratégia de Tradução Semântica
O `VanillaWebEmitter` utiliza o dicionário de metadados para desacoplar a visualização da fonte de dados:
- **Identifier-to-Label**: O `MvDocument` carrega os nomes de campos (`name`) que podem ser substituídos dinamicamente por um arquivo de tradução JSON.
- **UTF-8 Enforcement**: O sistema exige codificação UTF-8 absoluta para evitar a quebra de caracteres acentuados (comuns no ecossistema médico brasileiro) que invalidariam o Root Hash.

## 3. Formatação Regional (Locale)
Para garantir a paridade com o sistema MV, os seguintes padrões são aplicados:
- **Datas**: Padrão ISO internally (`YYYY-MM-DD`), exibido conforme o contexto do navegador ou configurações do layout Jasper.
- **Moeda e Números**: A vírgula `,` é o separador decimal padrão para processamento de regras matemáticas em PT-BR, sendo convertida para `.` durante a execução do motor JS.
