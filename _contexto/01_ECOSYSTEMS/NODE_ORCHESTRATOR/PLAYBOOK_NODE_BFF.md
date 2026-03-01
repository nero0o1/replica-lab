# PLAYBOOK NODE BFF - Orquestração e Emitter Web

## 1. Motor de Ejeção: StateOrchestrator
O emissor web deve injetar o `StateOrchestrator (ES6)` para gerenciar a reatividade clínica:
- **Unified State**: O estado de um campo (visível, habilitado, valor) é a união calculada de todas as regras que o afetam.
- **Priority Union (Defensive Restricted Priority)**: Em caso de conflito entre regras, a **maior restrição** sempre prevalece.
    - `DISABLE` sobrepõe `ENABLE`.
    - `HIDE` sobrepõe `SHOW`.
    - Esta é uma regra defensiva provisória para mitigar a ausência de precedência oficial no motor MV.
- **Active Set Guard**: Para mimetizar o "Shadow Loop Reentrancy", usar um `Set` de `activeNodes` para evitar estouro de pilha durante regras em cascata.

## 2. Serialização Matrioska e Blindagem
- **Inception Content (Rules of Minification)**: O `layouts.content` deve ser **SEMPRE compactado**. O `JSON.stringify()` deve ser usado sem argumentos de indentação.
- **Minificação Absoluta**: Proibido whitespaces ou quebras de linha literais. O resultado deve ser uma string monolítica escapada.
- **Nível 2 Escaping**: Substituir saltos de linha literais (`\n`) por espaços na carga blindada.
- **Base64 Safety**: Cargas opacas de scripts ou imagens devem ser trafegadas em Base64 para imunidade a parsers de terceiros.

## 3. Componentes e Comportamento Visual
- **Pixel-Perfect Rendering**: Usar CSS `position: absolute` com unidades fixas em `px`.
- **Coordenadas de Grid**: Respeitar o `width` e `height` da AST. Aplicar "snap-to-edge" se um componente for renderizado fora dos limites (X/Y negativos).
- **Theming**: Injetar propriedades capturadas como CSS Variables (ex: `--mv-field-label-color`).

## 4. Sessão e Snapshots
- **data-initial-state**: Cada componente deve carregar seu estado inicial de renderização para suportar o "State Reversal".
- **Quarentena Visual**: Aplicar borda laranja e cursor de ajuda para componentes com lógica inerte server-side.
