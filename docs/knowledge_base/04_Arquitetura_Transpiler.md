# 04 - ARQUITETURA DO TRANSPILER E MECANISMOS DE CONVERSÃO

Este documento detalha o funcionamento interno do motor de transposição (Transpiler) do projeto. Aqui explicamos como transformamos pedaços de arquivos XML e binários em uma estrutura de dados processável e vice-versa.

## 1. O Modelo Canônico: A Árvore de Sintaxe Abstrata (AST)

A peça central da nossa arquitetura é a **AST (Abstract Syntax Tree)**. Ela não é um arquivo, mas uma representação mental e computacional de um formulário. Por que não trabalhamos diretamente com XML ou JSON?
1.  **Imunidade a Formatos:** Se a MV decidir mudar de JSON para YAML amanhã, nossa AST permanece a mesma. Basta trocar o serializador.
2.  **Validação Antes da Escrita:** Podemos verificar se um hash está correto ou se um ID é duplicado antes mesmo de tentar salvar o arquivo no disco.

---

## 2. O Desafio do JasperReports e o Padrão "Vault" (Cofre)

Uma das maiores dificuldades da engenharia reversa do sistema MV é lidar com a tag `LO_REL_COMPILADO`. Esta tag contém um "blob" binário que é, na verdade, um arquivo de relatório Java (JasperReports) compilado.

### 2.1 Por que não podemos editar esse binário?
O JasperReports utiliza serialização binária do Java. Se alterarmos um único caractere nesse bloco tentando "limpá-lo", a estrutura interna de classes do Java quebra. O resultado é o famoso erro `NullPointerException` ou `InvalidClassException` que assombra usuários do Editor legados.

### 2.2 Como o "Vault" protege o Sistema
Implementamos um padrão chamado **Vault (Cofre)**:
- Durante a importação de um documento `.edt`, o sistema identifica o bloco Jasper.
- Em vez de tentar interpretá-lo, nós o extraímos e colocamos em um "contêiner seguro" (`MvLegacyPayload`).
- Ao gerar o novo documento, o transpiler simplesmente reinjeta esse binário original no local correto. Isso permite que o formulário seja editado na nossa ferramenta enquanto mantém a compatibilidade 1:1 com os motores de impressão da MV.

---

## 3. Geometria de Telas: Coordenadas Cartesianas vs. Relativas

O Editor 2 (Legado) trabalha com pixels absolutos. Se um botão está na posição `X: 10, Y: 10`, ele estará lá independente do tamanho da tela. Isso cria problemas em dispositivos modernos (tablets, celulares).

### 3.1 O Motor de Conversão de Coordenadas
Nosso transpiler utiliza uma lógica de **Ancoragem Dinâmica**:
- Ao ler o XML legado, capturamos as coordenadas brutas.
- A AST as processa e gera uma geometria de "Bounding Box".
- Ao exportar para o Editor 3 ou Web, o sistema calcula se aquele componente ainda cabe na tela. Se um componente for desenhado fora dos limites (`Out of Bounds`), o motor de conversão aplica um "snap-to-edge" (puxar para a borda), garantindo que nada desapareça por erros de cálculo milimétricos herdados da conversão.

---

## 4. O Paradoxo do ID Negativo (Identidade em Memória)

No sistema MV, um campo só ganha um ID real depois de ser salvo no banco de dados. Como, então, podemos criar novos campos em nossa ferramenta e definir que o Campo B é filho do Campo A?

### 4.1 A Solução da Identidade Sequencial Negativa
Criamos um sistema de **IDs Temporários**. Todo componente criado em memória recebe um ID negativo (ex: `-1001`, `-1002`).
- Isso serve como um "placeholder" seguro. 
- As regras de negócio e hierarquias são amarradas a esses IDs negativos. 
- Somente no momento do salvamento final na base da MV é que fazemos o "de-para", trocando esses placeholders pelos IDs reais gerados pelas tabelas globais (`SEQ_MAP_EDITOR_MV`).

---

## 5. Fluxo de Operação do Transpiler (Pipeline)

Para o NotebookLM, o fluxo lógico pode ser resumido nos parágrafos abaixo:

O processo começa com o **Ingestion Layer** (Camada de Ingestão), onde parsers leem a fonte (XML ou JSON) e transformam tudo em objetos genéricos de "Propriedade". Em seguida, o **Semantic Processor** aplica o dicionário de dados (Documento 02) para dar significado àqueles números. Uma vez que temos uma AST válida, o sistema pode realizar o **Logical Refinement** (Refinamento Lógico), validando os hashes (Documento 01) e o grafo de dependências das regras (Documento 03). Por fim, o **Emission Layer** gera o arquivo final desejado, garatindo a reinjeção dos binários do Jasper via Vault.

> [!NOTE]
> Este documento é o mapa de engenharia do projeto. Utilize-o para entender o roteamento de dados entre os diferentes módulos de código na pasta `src/`.
