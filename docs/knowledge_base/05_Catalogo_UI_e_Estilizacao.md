# 05 - CATÁLOGO DE UI E DIRETRIZES DE ESTILIZAÇÃO

Este manual serve como o guia definitivo para a camada de apresentação do Projeto Réplica MV. Ele cataloga os componentes visuais suportados e descreve como nossa Árvore de Sintaxe Abstrata (AST) traduz metadados de design em interfaces Web com paridade visual absoluta (Pixel-Perfect).

## 1. Inventário de Componentes de Interface

Para garantir que a réplica de um formulário seja indistinguível do original, mapeamos os componentes clássicos do Editor MV para seus equivalentes modernos, preservando seu comportamento semântico.

### 1.1 Componentes de Entrada e Texto
| Componente | Função Clínica | Comportamento Web |
|---|---|---|
| **TEXT** | Entrada de dados alfanuméricos curtos. | Renderizado como `<input type="text">` com suporte a máscaras. |
| **LABEL** | Títulos, instruções e rótulos fixos de tela. | Renderizado como `<span>` ou `<label>` dependendo do contexto. |
| **COMBOBOX** | Seleção única em listas pré-definidas. | Renderizado como um componente de Select customizado (Searchable). |
| **RADIOBUTTON** | Opções mutuamente exclusivas (ex: Sim/Não). | Agrupamento de inputs de rádio com navegação por teclado. |
| **CHECKBOX** | Seleções binárias ou múltiplas. | Input do tipo checkbox com estado persistido como 'S'/'N' ou boolean. |

### 1.2 Componentes Avançados e de Mídia
| Componente | Função Clínica | Comportamento Web |
|---|---|---|
| **DYNAMIC-TABLE** | Grids de dados repetíveis (ex: Itens de Prescrição). | Renderizado como uma tabela interativa com suporte a adição/remoção. |
| **IMAGE** | Exibição de logotipos ou diagramas anatômicos. | Tag `<img>` com tratamento de blobs vindos do banco Oracle. |
| **BARCODE** | Geração de etiquetas para rastreabilidade. | Gerado via biblioteca de canvas/SVG no front-end baseado no valor. |

---

## 2. Captura de Estilo pela AST (Design Tokens)

Diferente de ferramentas de web design comuns, o Editor MV armazena o estilo como propriedades anexas ao objeto do campo. Nossa AST captura esses metadados e os organiza em um objeto de `style` neutro.

### 2.1 Tipografia (`fontFamily` e `fontSize`)
O sistema legado utiliza fontes padrão do sistema Windows (como Arial, Tahoma e MS Sans Serif). 
- **Estratégia de Captura:** A AST identifica o nome da fonte original.
- **Normalização Web:** Mapeamos essas fontes para pacotes de fontes modernas ou stacks CSS seguras (Sans-Serif) para garantir legibilidade em alta densidade de informação.

### 2.2 Esquema de Cores (`color` e `backgroundColor`)
As cores no MV são frequentemente armazenadas como valores decimais ou hexadecimais do padrão Windows (BGR). 
- **Nossa Conversão:** Capturamos o valor bruto e o convertemos para o padrão CSS Hex (`#RRGGBB`). 
- **Acessibilidade:** Se uma cor de fundo for detectada mas a cor do texto for omitida, a AST aplica uma heurística de contraste para garantir que a informação clínica seja sempre visível.

### 2.3 Fronteiras e Bordas (`borderWidth` e `borderRadius`)
O design do Editor 2 é "seco", focando em bordas retas e funcionais. 
- **Captura:** O atributo de borda define se o componente é plano (Flat) ou possui relevo (3D/Inset). 
- **Paridade:** Traduzimos isso diretamente para propriedades `border` e `box-shadow` em CSS, simulando o visual clássico do sistema sem sacrificar a flexibilidade da Web.

---

## 3. O Motor de Renderização Pixel-Perfect

O grande diferencial do projeto é a fidelidade visual. Para atingir 100% de paridade, o motor Web utiliza um sistema de **Coordenadas de Grid Absoluto**.

### 3.1 Unidades de Medida
Embora a Web favoreça unidades relativas (`em`, `rem`, `%`), o formulário médico original depende de precisão milimétrica para impressão em formulários pré-impressos.
- **Lei da Renderização:** O motor utiliza `px` (pixels) como unidade base, respeitando o `width` e `height` definidos no metadado do layout.

### 3.2 Camada de CSS Base (Theming)
Para evitar a repetição de código, todos os componentes compartilham uma folha de estilos base que define o "look-and-feel" comum da MV. As propriedades capturadas pela AST (como a cor específica de um campo) são injetadas como **CSS Variables (Custom Properties)**.

**Exemplo Lógico:**
Se a AST detecta um rótulo vermelho, ela gera:
```css
/* Gerado dinamicamente no componente */
.mv-field-label {
    --mv-label-color: #FF0000;
    color: var(--mv-label-color);
}
```

## 4. Conclusão: Por que o Estilo é Crítico?

Em um ambiente hospitalar, a mudança visual pode causar confusão cognitiva. Um médico acostumado a ver um alerta em "Arial Negrito Vermelho" por 10 anos pode ignorá-lo se ele for renderizado em um design web moderno demais ou minimalista. A paridade visual não é um capricho estético, é uma medida de **segurança do paciente** e **facilidade de adoção**.

> [!IMPORTANT]
> Para o NotebookLM: Utilize este catálogo para entender como a aparência visual é tratada como um dado técnico rigoroso na nossa arquitetura, garantindo a continuidade da experiência do usuário legado.
