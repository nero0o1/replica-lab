# Análise de Lacunas (Gap Analysis)

## 1. Leis da Fidelidade vs. Estado Atual
- [x] **Lei dos IDs**: Implementada no Core (Manifesto criado).
- [x] **Lei da Serialização**: Implementada no DriverV3 (JSON-in-String).
- [x] **Lei da Integridade MD5**: Implementada parcialmente (Bools estáticos + Strings).
- [x] **Lei da Tipagem Oracle**: Driver deve garantir que ints e bools não tenham aspas.

## 2. IDs Desconhecidos (Unknowns)
Com base na varredura inicial, os seguintes IDs apareceram em logs ou documentação antiga mas não têm comportamento definido no Manifesto:

- **ID 43**: Apareceu em logs de erro. Suspeita: Container ou Grupo Visual.
- **ID 21**: Mapeado anteriormente como "Acao SQL", mas conflita com ID 4? Precisamos verificar se ID 4 é "Botão" e ID 21 é a "Propriedade SQL" do botão.
    - *Ação*: Verificar dump de botão.

## 3. Padrões de Hash Desconhecidos (MD5 Salt)
A "Lei da Integridade" exige hash para tudo.
- **Dúvida**: Nomes de usuários e Datas dinâmicas (timestamp de geração) entram no Hash da Versão?
- **Evidência**: O `version.hash` parece depender apenas do `data` estático. Metadados voláteis (quem gerou, quando) geralmente ficam fora do `data` ou são ignorados pelo algoritmo de hash do Editor 3.
- **Teste Necessário**: Gerar o mesmo arquivo em horários diferentes e verificar se o `version.hash` muda. Se mudar, nossa engenharia reversa do hash está incompleta.
