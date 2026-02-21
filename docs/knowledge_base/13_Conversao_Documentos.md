# 13 - CONVERSÃO DE DOCUMENTOS EXTERNOS (WORD/PDF ➔ LABELS)

Este dossiê detalha o protocolo de ingestão de documentos externos para o ecossistema Réplica MV, garantindo que o conteúdo textual seja preservado com integridade visual e espacial.

## 1. O Conceito de "Label Matrix"

Diferente da importação entre editores, documentos vindos de Word ou PDF não possuem metadados de componentes (como IDs de campos ou gatilhos). Eles chegam como blocos de texto puro.
- **Protocolo**: Todo bloco de texto importado é inicialmente mapeado como um componente de **Texto Estático (Label)** utilizando a `CD_PROPRIEDADE = 1` no Oracle.
- **Estrutura**: O sistema cria uma árvore de labels posicionados de forma absoluta no canvas.

## 2. A Fórmula Crucible de Transposição Espacial

PDFs e documentos Word usam diferentes sistemas de medição (Points vs Pixels). Para garantir que o layout não "exploda" ao ser carregado no Editor 3, aplicamos a matriz de conversão:
- **Resolução de Referência**: 96 DPI (Web Standard).
- **Fórmula**: `Px_MV = (Px_Origem / DPI_Origem) * 96`.
- **Efeito**: Isso garante que uma linha de texto que ocupa 10cm no Word ocupe exatamente o mesmo espaço visual no Editor MV, permitindo a impressão assistencial sem distorções.

## 3. Identificação de Placeholders (Auto-Discovery)

Um documento importado como label é "morto" (não aceita entrada de dados). Para "revivê-lo", o motor de transposição busca por padrões visuais que indicam intenção clínica:
- **Padrão `[ ]`**: Convertido automaticamente para um `CHECKBOX` reativo.
- **Padrão `__________`**: Convertido para um campo de `TEXTO (VARCHAR2)` com o prefixo `TXT_`.
- **Padrão `( )`**: Convertido para um `RADIOBUTTON`.

## 4. Limites de Caratêres e Fragmentação Oracle

O RDBMS Oracle possui um limite rígido de 4000 caracteres para campos do tipo `VARCHAR2` na tabela `PAGU_METADADO_P`.
- **Ação**: Blocos de texto contínuos no Word que excedam este limite são automaticamente fragmentados em múltiplos labels sequenciais.
- **Integridade**: O sistema mantém um `Z-Index` contínuo para garantir que a leitura por softwares de acessibilidade ou exportação para PDF mantenha a ordem lógica original.

> [!TIP]
> Use este dossiê para planejar a ingestão de protocolos clínicos baseados em guias de papel escaneadas ou documentos de texto antigos.
