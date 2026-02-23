# Dossiê 16: Motor de Blindagem de Interface

## 1. Funcionamento do Código (Deep Dive)
O "Motor de Blindagem" (`ShieldingEngine`) opera em três fases sequenciais para garantir que a interface seja transportada sem riscos de corrupção:

### Fase A: Captura de Estado (`_capturar_estado_tela`)
O sistema percorre a árvore de objetos (AST) de forma recursiva. Ele extrai apenas os pares chave-valor essenciais, transformando objetos complexos de memória em um mapa simples (Dicionário ou Hashtable).

### Fase B: Escapamento Rigoroso (`blindar_interface`)
Antes de codificar, o sistema aplica um "Escapamento de Nível 2":
- **Double Backslash**: Transforma `\` em `\\` para evitar que interpretadores gulosos consumam o caractere de escape.
- **Line Sanitization**: Substitui saltos de linha literais (`\n`) por espaços, garantindo que a carga final resida em uma **linha única**.

### Fase C: Safeguard de Transporte (Base64)
A string resultante é convertida em um stream de bytes UTF-8 e então codificada em Base64. 
- **Resultado**: Uma carga composta apenas por `[A-Za-z0-9+/=]`.
- **Vantagem**: Este alfabeto é imune a aspas simples, duplas, hashtags ou colchetes, tornando-o indestrutível perante parsers SQL, XML ou JSON de terceiros.

## 2. Regras de Resiliência
1.  **Imutabilidade de Transporte**: Uma vez blindada, a carga não deve ser manipulada como texto; apenas transportada.
2.  **Validação de Retorno**: Todo processo de blindagem deve ser testável pelo método inverso (`ler_tela_blindada`). Se a reversão falhar, o artefato original é considerado perigoso e deve ser descartado.

## 3. Por que isso é Vital?
No ecossistema clínico, médicos e enfermeiros podem colar textos de outros sistemas contendo caracteres de controle invisíveis ou aspas em cascata. Sem o Motor de Blindagem, um simples parêntese não fechado em uma observação clínica poderia derrubar o parsing de todo o layout do formulário, causando perda de produtividade ou erros de visualização.

---
*Referência Técnica: `src/core/shielding_engine.py`*
