**Objetivo:** Estabelecer a arquitetura lógica e as diretrizes estritas para a construção do motor de conversão bidirecional (Transpiler) entre o formato legado baseado em marcação (XML - Editor 2) e o padrão atual orientado a objetos (JSON Flow - Editor 3) do sistema MV.

---

## 1. Topologia da Árvore Legada (XML - Editor 2)
O parser deve ser capaz de interpretar a estrutura XML hierárquica legada. A árvore do Editor 2 organiza dados e metadados de forma posicional e baseada em nós aninhados.

**Estrutura Base Esperada:**
```xml
<documento nome="NOME_DO_ARQUIVO" codigo="NUMERO_INTEIRO">
    <metadados>
        <criado_por>MATRICULA_USUARIO</criado_por>
        <criado_em>YYYY-MM-DD HH:mm:ss</criado_em>
        </metadados>
    <layout largura="768" altura="1000">
        <componentes>
            <campo id="3251" tipo="TEXT" x="10" y="560">
                <propriedades>
                    <propriedade id="1" nome="tamanho">100</propriedade>
                    <propriedade id="8" nome="obrigatorio">true</propriedade>
                    <propriedade id="4" nome="acao"><![CDATA[SELECT * FROM DUAL]]></propriedade>
                </propriedades>
            </campo>
            </componentes>
    </layout>
</documento>
Atenção Léxica: Blocos SQL ou textos formatados no Editor 2 frequentemente utilizam tags <![CDATA[...]]> para escapar caracteres especiais. O transpiler deve extrair o conteúdo bruto dessa tag.2. Topologia do Padrão Atual (JSON Flow - Editor 3)A saída (ou entrada, no caso da engenharia reversa) deve seguir estritamente o contrato de API do Editor 3. A estrutura agrupa metadados globais em propertyDocumentValues e aloca a renderização visual dentro de uma string ou sub-árvore em content -> pageBody -> children.Estrutura Base Esperada:JSON{
  "documentName": "NOME_DO_ARQUIVO",
  "itemType": {
    "id": 13,
    "identifier": "DOC",
    "description": "Documento"
  },
  "propertyDocumentValues": [
    {
      "property": {
        "id": 10,
        "identifier": "criado_por"
      },
      "value": "MATRICULA_USUARIO"
    }
  ],
  "layouts": [
    {
      "description": "Tela",
      "width": 768,
      "height": 1000,
      "versionId": 333,
      "content": "{\"pageBody\":{\"children\":[{\"id\":3251,\"name\":\"componente_1\",\"visualizationType\":\"TEXT\",\"x\":10,\"y\":560,\"fieldPropertyValues\":[{\"property\":{\"id\":8,\"identifier\":\"obrigatorio\"},\"value\":\"true\"}]}]}}"
    }
  ]
}
Atenção Estrutural: O atributo content no Editor 3 frequentemente é armazenado como uma string JSON escapada (Stringified JSON) pelo motor do banco de dados. O transpiler deve aplicar JSON.parse() na ida e JSON.stringify() na volta para manipular os dados internos sem corromper a carga.3. Diretrizes de Transpilação BidirecionalParse de Entrada (XML $\rightarrow$ JSON):Iterar sobre <componentes>.Extrair atributos espaciais (x, y, width, height).Mapear <propriedade> utilizando o dicionário canônico definido no MAPEAMENTO_PRIMITIVOS.md.Montar a árvore de fieldPropertyValues.Parse de Retorno (JSON $\rightarrow$ XML):Decompor a string content.Iterar sobre children.Reconstruir a hierarquia <campo> -> <propriedades>.Envolver instruções SQL e quebras de linha obrigatórias em <![CDATA[...]]>.4. Regras Estritas de Tratamento de Falhas e Degradação Segura (Fallback)Ao lidar com defasagem tecnológica entre as versões (campos descontinuados no Editor 2 ou novos requisitos no Editor 3), o agente deve operar sob princípios de Zero-Trust de Dados:Regra 1 (Orfandade de Propriedades): Se o transpiler encontrar uma <propriedade> no XML legado que não possui mapeamento correspondente ou não existe no novo schema JSON do Editor 3:Ação: A execução não deve ser interrompida.Tratamento: O script deve logar um aviso (WARN) contendo o ID e o valor da propriedade ignorada.Fallback: Aplicar um "valor padrão seguro" (Safe Default) que garanta a renderização do componente sem risco de travamento (ex: strings vazias "" para textos, false para booleanos críticos de trava como obrigatorio, ou null para propriedades semânticas inexistentes).Exemplo de Log de Saída: [WARN] Unmapped XML Property: ID 99 (legacy_flag) no componente 3251. Fallback aplicado: null.Regra 2 (Propriedades Mandatórias Faltantes):Se o JSON do Editor 3 exigir uma propriedade para renderização (ex: visualizationType) que não pôde ser inferida do XML:Ação: Injetar valor base genérico (ex: "LABEL") para evitar falha de parser na IDE.Tratamento: Logar criticidade alta (ERROR/WARN).Regra 3 (Inconsistência de Tipagem):Se o valor extraído no XML for incompatível com a coerção definida para o JSON (ex: esperando boolean e recebe "TALVEZ"):Ação: Descartar a string inválida, forçar o valor lógico negativo (false) e registrar o desvio no log de operação.
* **Regra 4 (Descolamento Espacial - Out of Bounds):**
    Se um componente extraído do XML possuir coordenadas (`x`, `y`) negativas ou que ultrapassem os limites absolutos definidos na raiz do documento (`width`, `height`):
    * **Ação:** Ancorar as coordenadas ao limite seguro mais próximo (exemplo: `x < 0` $\rightarrow$ `x = 0`).
    * **Tratamento:** Registrar um aviso (WARN) de reajuste espacial no log, prevenindo quebra de layout invisível na engine de renderização (React/Angular) do Editor 3.

## 5. Algoritmo de Achatamento e Reconstrução de Hierarquia (Flattening vs Nesting)
As arquiteturas tratam a relação pai-filho (Parent-Child) de maneira antagônica. O script conversor deve aplicar algoritmos de travessia específicos para cada direção.

* **Sentido XML $\rightarrow$ JSON (Desaninhamento / Flattening):**
  * O XML agrupa itens visualmente, encapsulando tags (ex: `<secao><campo id="1"/></secao>`).
  * O parser deve percorrer a árvore (Tree Traversal), extrair a tag pai e achatá-la.
  * No JSON resultante, todos os componentes coexistem no array `children`. A paternidade é estabelecida mapeando o ID do nó pai para os atributos relacionais `fieldParentId` e `fieldParentIdentifier` do nó filho.

* **Sentido JSON $\rightarrow$ XML (Aninhamento / Nesting):**
  * O JSON possui um array plano. O script deve agrupar os objetos em memória utilizando os identificadores relacionais (`fieldParentId`).
  * Em seguida, instanciar a estrutura de nós aninhados para gerar o XML. 
  * Se um componente no JSON declarar um `fieldParentId` que não existe no payload atual (Orphan Node), o motor deve promover o componente ao nó raiz (`<layout>`) e disparar um log de erro de integridade estrutural.

## 6. Motor de Sanitização Léxica e Tratamento de CDATA
O transpiler atuará como barreira de segurança sanitária contra injeções ou corrupção de caracteres em transições de banco de dados.

* **Ingestão de SQL e Regras de Negócio:**
  * O XML aloca queries e lógicas dentro de nós textuais ou `<![CDATA[...]]>`.
  * Na conversão para JSON, o texto bruto deve ser escapado corretamente. Aspas duplas (`"`) dentro de instruções `SELECT` devem virar `\"`. Aspas simples (`'`) devem permanecer intactas, visto que a engine Oracle depende delas para literais de string.
* **Erradicação de Control Characters:**
  * Componentes `TEXTAREA` ou instruções SQL frequentemente herdam quebras de carro (`\r`) do Windows. O conversor **deve** interceptar e substituir as sequências `\r\n` universalmente por `\n` antes de montar o JSON.
* **Double-Stringify no Editor 3:**
  * Atenção crítica: O nó `content` no JSON do Editor 3 não é um objeto nativo, mas sim uma string que encapsula um JSON. O script deve construir o objeto hierárquico internamente e, no último passo de saída, aplicar a função de `stringify` sobre a sub-árvore do `pageBody`, escapando as chaves internas para suportar o armazenamento do MV.

## 7. Mapeamento de Arrays e Domínios Fechados (`lista_valores`)
Componentes como `COMBOBOX` e `RADIOBUTTON` exigem opções pré-definidas. 

* **No XML:** Geralmente, as opções são apresentadas como uma string delimitada (ex: `M=Masculino|F=Feminino`) ou em tags iterativas `<opcao valor="M">Masculino</opcao>`.
* **No JSON:** Devem ser alocadas na chave de propriedade correspondente (`lista_valores`, ID 52) preservando a separação esperada pela engine do MV (frequentemente o caractere pipe `|` ou ponto e vírgula `;`). O transpiler deve validar se a string concatenada atende à máscara delimitadora antes de injetar.

## 8. Ciclo de Vida e Auditoria (Hashes de Integridade)
O controle de versionamento das entidades exige manuseio cuidadoso das assinaturas criptográficas atreladas a cada propriedade no JSON.

* **Ida (XML $\rightarrow$ JSON):** Se o XML legado não possuir hash para as propriedades computadas, o transpiler deve calcular um MD5 determinístico baseado na concatenação do `identifier` e do `value`, ou forçar o valor `null` na chave `hash`, transferindo a responsabilidade da geração de hash para a API do backend no momento do upsert.
* **Volta (JSON $\rightarrow$ XML):** Os hashes MD5 intrínsecos do JSON devem ser descartados se o protocolo XML de destino não possuir tag de armazenamento para auditoria, ou alocados como atributos auxiliares estáticos (ex: `hash="b326b..."`) caso a reconstrução exata da origem seja mandatória.
* O transpiler jamais deve alterar propriedades de histórico de auditoria (`criado_por`, `criado_em`, `publicado_em`) durante o fluxo. Elas devem sofrer *pass-through* (reprodução exata 1:1).

## 9. Gatilhos de Parada Crítica (Hard Failures)
O transpiler deverá abortar a operação (`exit code 1`) e recusar a geração do arquivo de saída se e somente se:
1. O XML/JSON de entrada for malformado sintaticamente, impossibilitando o parse inicial.
2. O artefato não contiver o identificador global mandatório (`documentName` no JSON ou atributo `nome` na tag raiz do XML).
3. A string do atributo `content` do JSON for decodificada e não contiver a chave estrutural raiz esperada (`pageBody`), indicando corrupção severa da árvore de renderização.

# Arquitetura do Motor de Transformação Bidirecional

## Design Pattern: Árvore de Sintaxe Abstrata (AST)
O sistema não deve traduzir XML diretamente para JSON. A arquitetura exige um modelo intermediário (AST):
1. **Parser:** Lê o documento de origem (MV2 XML ou MV3 JSON) e o converte para um Objeto de Memória Neutro (AST).
2. **Hash Engine:** Injeta o algoritmo MD5 descoberto:
   - Root Hash: `MD5(id + identifier + visualizationType.identifier)`
   - Property Hash: `MD5(value)`
3. **Serializer (Exporter):** Pega o AST e o cospe no formato de destino.

## Tratamento de Componentes (visualizationType)
Garantir o parsing correto dos seguintes identificadores principais extraídos das amostras:
`TEXT`, `TEXTAREA`, `LABEL`, `CHECKBOX`, `RADIOBUTTON`, `COMBOBOX`, `DATE`, `DYNAMIC-TABLE`, `GRID`, `IMAGE`, `IMAGEMARKER`, `BARCODE`, `AUDIOMETRY`, `CHART`, `CONDITIONAL-SECTION`.