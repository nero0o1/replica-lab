# 01 - CRIPTOGRAFIA E INTEGRIDADE DE DADOS NO ECOSSISTEMA MV

O sistema Editor 3 da MV baseia sua confiança e segurança clínica em um mecanismo rigoroso de assinaturas digitais. Este documento explora as entranhas do protocolo de segurança, explicando o porquê de cada decisão técnica e como elas se manifestam na prática da engenharia reversa.

## 1. A Filosofia da "Verificação de Santidade" (Sanctity Check)

Diferente de sistemas modernos de gestão de formulários que confiam na integridade do banco de dados ou da rede, o sistema MV implementa uma camada de verificação no nível da aplicação. Cada campo e cada propriedade de um documento possui uma assinatura criptográfica. O objetivo primordial não é o sigilo (criptografia de esconder), mas a **integridade** (garantir que nada foi alterado). Se um administrador de banco de dados tentar alterar um valor SQL diretamente em uma tabela sem o conhecimento do motor da aplicação, o Editor 3 detectará o descompasso de hash e invalidará o documento inteiro, impedindo o uso clínico de informações potencialmente corrompidas.

O algoritmo escolhido para essa tarefa é o **MD5 (Message Digest 5)**. Embora seja considerado obsoleto para criptografia de senhas devido a colisões, sua velocidade e determinismo o tornam ideal para checksums de milhares de metadados em tempo real durante o carregamento de prontuários complexos.

## 2. A Engenharia do Hash no Editor 3

A aplicação dos hashes ocorre de forma hierárquica e determinística, dividida em dois grandes grupos: a identidade do componente e o conteúdo de seus atributos.

### 2.1 Root Hash: A Digital de Identidade
O Root Hash garante que o "esqueleto" de um campo não foi trocado por outro. Para calcular este hash, o motor da MV concatena três elementos fundamentais sem nenhum tipo de separador ou caractere especial entre eles. Essa colagem de dados gera uma string bruta que é então convertida em bytes UTF-8 e assinada pelo MD5. Os elementos são:
1.  **ID Interno:** O identificador numérico único atribuído pelo banco de dados.
2.  **Identificador Técnico:** O nome curto do campo (ex: `TXT_OBSERVACOES`).
3.  **Tipo de Visualização (ID):** O ID que define se o campo é um texto, um combo ou um checkbox.

**Analogia:** Imagine o Root Hash como o DNA de um ser vivo. Se você mudar a espécie ou o nome da espécie, o DNA original não corresponde mais ao ser, invalidando sua identidade.

### 2.2 Property Hash: Integridade de Metadados
Cada uma das propriedades (tamanho, cor, SQL, obrigatoriedade) possui seu próprio hash individual. Isso é feito para que o sistema possa detectar sabotagens pontuais. Se apenas a propriedade de "Obrigatoriedade" for trocada de Sim para Não via banco de dados, o hash da propriedade falhará, mas o Root Hash permanecerá válido.

---

## 3. Tratamento de Especialidades e Anomalias Históricas

O motor de hash da MV possui comportamentos peculiares derivados de sua herança de décadas em Java e Oracle, que exigem uma higienização absoluta dos dados.

### 3.1 A Anomalia do Zero à Esquerda (Leading Zero)
Devido ao modo como certas versões legadas do motor de persistência interpretavam o hash MD5 (tratando a assinatura hexadecimal de 32 caracteres como se fosse um número decimal em alguns momentos), assinaturas que começam com o caractere "0" sofrem um erro de truncagem. Na nossa réplica, é obrigatório garantir que o hash seja sempre uma string completa de 32 caracteres. Se o MD5 resultar em algo menor, nós "preenchemos" com o zero faltante para manter a paridade com o validador original do sistema.

### 3.2 O Paradoxo do Booleano
No banco de dados Oracle, valores lógicos são frequentemente armazenados como strings 'S' (Sim) ou 'N' (Não). No entanto, o motor de hash do Editor 3 é orientado a objetos. Isso significa que, antes de assinar o valor, ele converte o 'S' do banco para a string literal `"true"` do JSON. Se tentarmos calcular o hash sobre a letra 'S', a verificação de integridade falhará miseravelmente. O sistema exige a conversão para os literais minúsculos do padrão booleano.

### 3.3 A Regra de Omissão para Valores Nulos (Nulls)
Um valor nulo ou vazio não é uma string vazia `""`. Para o sistema MV, um valor nulo significa a ausência total de metadado. Portanto, campos nulos **não possuem hash**. Tentar gerar um MD5 sobre o valor `null` é tecnicamente impossível e semanticamente incorreto. Em nossa estrutura de dados, o campo de hash deve ser marcado explicitamente como `null` para evitar que o validador tente buscar uma assinatura inexistente.

### 3.4 Sanitização de Espaços e Quebras de Linha
Muitas vezes, ao copiar e colar scripts SQL entre diferentes editores, caracteres invisíveis como o "Retorno de Carro" (`\r` do Windows) são inseridos. O motor da MV é "limpo": ele ignora esses resquícios e foca apenas na "Nova Linha" (`\n` do Unix). Nossa lógica de integridade deve purificar qualquer entrada de texto, removendo espaços em branco das extremidades e padronizando quebras de linha para garantir que o hash calculado coincida bit a bit com o esperado pela aplicação.

---

## 4. Resumo de Diretrizes para Consumo de Dados

| Elemento | Regra de Ouro | Por que importa? |
|---|---|---|
| **Encoding** | Sempre UTF-8 | Evita quebras de caracteres acentuados que invalidam o hash. |
| **Booleano** | Usar `"true"` ou `"false"` | O hash é calculado sobre o tipo JSON, não sobre o valor SQL. |
| **ID do Campo** | Deve ser o ID real do banco | Integração direta com a tabela `CD_CAMPO`. |
| **Sanitização** | Remover `\r` e espaços | Pequenas divergências visíveis são falhas invisíveis de integridade. |
