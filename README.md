# 🏛️ Projeto Antigravity: Editor Forms
**Versão:** 1.0.0-alpha (Era Comum: 2024)
**Status:** Desenvolvimento Ativo / Protocolo P-11 & VT-3
**Arquiteto Responsável:** Francisco & MV-Antigravity AI

## 1. O Problema Central (O Gargalo de 72h)
O ecossistema MV (Editor 2/Flow e Editor 3/Soul) impõe uma fricção burocrática na criação de documentos clínicos. Processos que envolvem tabelas complexas e regras de visibilidade levam atualmente ~3 dias e.c. (72 horas) para serem concluídos devido à interface rígida e ao acoplamento com metadados proprietários.

## 2. Objetivo Estratégico
Desenvolver uma ferramenta de **Engenharia Reversa Ativa** e **Geração Acelerada** que:
1. **Consuma:** Arquivos legados (`.edt`), PDFs e documentos Word.
2. **Normalize:** Transforme esses inputs em uma estrutura de dados JSON agnóstica.
3. **Produza:** Arquivos XML/JSON 100% compatíveis com o banco Oracle da MV, respeitando schemas de tabelas `PAGU_`.
4. **Liberte:** Permita a exportação desses mesmos documentos para interfaces concorrentes (Tazi, OSGH) sem perda de inteligência clínica.

## 3. Requisitos Técnicos de Rigor (Protocolo VT-3)
A IDE/Agente deve garantir paridade absoluta com os seguintes padrões:

### Mapeamento de Propriedades (`CD_PROPRIEDADE`)
O motor deve mapear as 43 propriedades fundamentais. Exemplos críticos:
- **ID 1-4:** Coordenadas de posicionamento (X, Y, Largura, Altura).
- **ID 8:** Obrigatoriedade (Booleano clínico).
- **ID 12:** Vinculação com Coluna do Banco (Mapeamento direto `PAGU_`).
- **ID 25:** Regras de visibilidade (Scripts).

### C. Geometria de Layout
Conversão precisa de unidades de medida. O que é desenhado na ferramenta deve resultar em milímetros exatos na impressão A4 do JasperReports/MV, evitando truncamento de dados.

## 4. O "Shortcut Engine" (Diferencial Competitivo)
A ferramenta não deve ser apenas visual (Drag-and-Drop). Ela deve permitir:
- **Layout via DSL (Code-First):** Criar tabelas e grids complexos via declaração de código C#.
- **Ingestão Inteligente:** Um parser que identifica campos em um PDF e sugere automaticamente o `CD_PROPRIEDADE` mais provável.
- **Injeção de Regras:** Automatizar a criação de fórmulas de cálculo e saltos de campos (tabulação lógica).

## 5. Próximos Passos Imediatos para a IDE
A IDE deve focar na construção dos seguintes módulos, nesta ordem:
1. **Parser de `.edt`:** Ler o XML legado e popular o objeto C# `DocumentModel`.
2. **Generator de Metadados:** Criar a função que gera o Hash MD5 e a estrutura XML que o sistema Soul aceita na importação.
3. **Interface de Edição (Electron):** Visualização rápida dos campos mapeados para validação visual.

---
**Aviso de Integridade:** Qualquer implementação que viole a estrutura das tabelas `PAGU_` ou que cause erro de `ORA-00001` (Unique Constraint) deve ser descartada imediatamente. O foco é Compatibilidade Irredutível.
##  1. Visão de Soberania TécnicaEste projeto não é um "clonador de formulários". 
É um Motor de Abstração Clínica. O objetivo é desacoplar a inteligência do documento (regras, campos, cálculos) da implementação proprietária da MV.O Mantra: "Escreva uma vez em nossa DSL/Interface, publique em qualquer lugar (MV Soul, Tazi, OSGH, PDF Inteligente)."2. O Modelo de Dados Abstrato (The Clean Core)Diferente do legado, nossa estrutura interna de dados (JSON) é agnóstica. Os "vícios" do sistema original (como prefixos TXT_, RDB_) só existem na Camada de Saída (Output Layer).A. Hierarquia de ObjetosDocumentContainer: Metadados globais (Título, Versão, Schema de Tabela PAGU_).PageModel: Definições geométricas (A4, Paisagem/Retrato, Margens em mm).ComponentTree: Coleção de objetos purificados:Field: (Id único, Tipo Semântico: Text, Number, Date, Choice).Visual: (X, Y, Width, Height, Z-Index, Estilo CSS-like).Binding: (Coluna real no Banco Oracle, CD_PROPRIEDADE_12).Behavior: (Regras de visibilidade, Fórmulas de cálculo).3. Deep Mapping: A Matriz de Propriedades (1-43)A IDE deve operar sobre o mapeamento exaustivo das propriedades CD_PROPRIEDADE. Abaixo, o detalhamento da "Matéria Escura" que o agente deve dominar:IDPropriedadeSignificado Técnico no MotorRigor P-111-4GeometriaPosicionamento absoluto. Conversão: 1 unidade MV = $n$ pixels (Calibrar via VT-3).Crítico para Impressão.8RequiredObrigatoriedade clínica. Bloqueia a assinatura do documento.Risco de Integridade.12Database BindO "Santo Graal". Vincula o campo à coluna da PAGU_ITPED_CLIN_ESTRUT.Imutável após criação.21Font StyleMapeamento de fontes (Arial, Courier) para renderização Delphi/Java.Estética e Legibilidade.25Visibility RuleOnde as regras residem. Scripts que determinam o fluxo do médico.Lógica de Negócio.30Lookup/SQLConsultas dinâmicas em DUAL ou tabelas de apoio (Ex: Medicamentos).Performance de Banco.4. Pipeline de Ingestão e "Shortcut Engine"Para reduzir o tempo de criação de 3 dias para < 4 horas, o motor deve executar os seguintes processos de "Arqueologia Ativa":Módulo 1: O Transpiler de "Documentos Mortos" (PDF/Word)Análise Geométrica: Identificar grids e linhas para sugerir tabelas PAGU_.OCR Semântico: Identificar palavras-chave (Ex: "Peso", "Altura", "Pressão") e mapear automaticamente para CD_PROPRIEDADE históricos já existentes no banco do cliente.Módulo 2: DSL (Domain Specific Language) em C#Em vez de cliques, a IDE deve suportar a criação via código:C#// Exemplo de como a ferramenta deve pensar internamente
var campoPeso = new ClinicalField("Peso")
    .AsNumeric(precision: 3, scale: 2)
    .BindTo("NR_PESO")
    .WithRule(v => v > 0 && v < 500)
    .SetPosition(10, 50); // mm
5. Protocolos de Segurança e Exportação (VT-3)A exportação para o formato .edt ou direto para o banco deve garantir:Integridade MD5: O hash de validação do arquivo deve ser recriado com precisão cirúrgica para que o importador do MV não rejeite o arquivo.Sanitização Win-1252: Tratamento de caracteres especiais para evitar quebra de encoding no Oracle legado.Independência de Vendor: Todo documento gerado DEVE ter um "Sidecar" em JSON puro. Se a MV for desligada hoje, o documento continua vivo e renderizável em HTML5/Canvas no nosso sistema.6. Ambição Técnica e Próximos PassosO objetivo final é o "One-Click EHR".Imediato: Implementar o parser que lê o XML do Editor 2 e o converte para este novo JSON Purificado.Médio Prazo: Criar o gerador de tabelas dinâmicas (o pesadelo atual de 3 dias).Longo Prazo: Interface Electron que permite o "Live Preview" do JasperReports antes mesmo de subir para o servidor MV.Nota para a IDE: Ao processar qualquer solicitação de código, verifique se a lógica respeita a separação entre a Camada de Visão (UI) e a Camada de Persistência (Oracle). Não permita acoplamento entre o nome do campo e o metadado do banco.
7. A Camada de Persistência: Arqueologia Oracle (PAGU_)
Para garantir a compatibilidade irredutível (VT-3), o motor deve entender que o documento não é apenas um arquivo, mas um espelho de tabelas relacionais complexas.

A. Estrutura de Destino (ITPED_CLIN)
Todo campo gerado na nossa ferramenta deve prever sua moradia final no banco Oracle:

Tabela Mestra: PAGU_ITPED_CLIN_ESTRUT (Metadados do layout).

Tabela de Dados: PAGU_VALOR_ESTRUT_DOCUMENTO (Onde o dado clínico reside).

Rigor P-11: O motor deve impedir a criação de dois campos apontando para o mesmo CD_PROPRIEDADE_12 (Coluna do Banco) no mesmo contexto de documento, evitando o Data Overwriting.

8. O Algoritmo de Alquimia de Coordenadas (Precision Mapping)
O maior desafio do Editor 2/3 é o "WYSINWYG" (What You See Is Not What You Get). O que aparece na tela do editor muitas vezes sai cortado no PDF do JasperReports.

A. Matriz de Conversão
O motor deve implementar uma constante de conversão baseada na DPI do sistema legado:

Unidade Interna (UIU): Pixels virtuais na interface Electron.

Unidade MV (MVU): A medida proprietária armazenada nos IDs 1 e 2.

Saída Física: Milímetros (ISO 216 - A4).

Lógica Antigravity: O motor calculará automaticamente o Padding de segurança para evitar que fontes em Negrito (Bold) estourem o limite do componente, um erro comum no Editor 3.

9. Injeção de Inteligência: O Motor de Regras (ID 25)
Atualmente, criar regras de visibilidade e saltos (Tabulação) é um processo manual e lento. Nossa ferramenta deve tratar regras como Código de Primeira Classe.

A. Transpiler de Script
Input: O usuário escreve em C# simplificado ou seleciona em uma UI visual: if (IDADE < 18) hide(CAMPO_RESPONSAVEL);.

Processamento: O motor converte essa lógica para o formato de script proprietário que o MV armazena na propriedade ID 25.

Validação: O sistema verifica se todos os CD_PROPRIEDADE mencionados na regra realmente existem no documento antes de gerar o .edt.

10. O "Shortcut Engine": Ingestão de Documentos Mortos
Este é o coração da redução de tempo (de 3 dias para 4 horas).

A. Pipeline de Conversão de PDF/Word
Layer Extraction: O motor decompõe o PDF em camadas de texto e vetores.

Grid Recognition: Identifica sequências de linhas horizontais e verticais para inferir Tabelas Clínicas.

Heurística de Campos: Se o motor encontrar o texto "Queixa Principal" seguido de uma linha, ele sugere automaticamente um componente Field do tipo TEXT (TXT_), vinculado à propriedade de "Texto Livre".

Auto-Coding: O motor gera os IDs internos sequenciais automaticamente, liberando o desenvolvedor para focar apenas na Regra Clínica.

11. O Protocolo de Segurança MD5 e Integridade
O sistema Soul só aceita arquivos cuja integridade seja comprovada.

Checksum Generator: Nossa ferramenta incluirá um módulo em C# que replica exatamente o algoritmo de Hash da MV para assinar o arquivo gerado.

Sanitização de Metadados: Remoção automática de caracteres invisíveis (como \r\n mal formados) que corrompem o parser do Editor 3.

12. SKILL.md: Instruções para Agentes Autônomos (AI Agents)
Para que os agentes (Gemini/GPT/Claude) ajudem o Francisco com maestria, eles devem seguir estas sub-rotinas:

Habilidade: GenerateClinicalField
Input: Nome do campo, Tipo de dado, Posição aproximada.

Ação: Consultar o mapa de CD_PROPRIEDADE, definir o ID 12 disponível e gerar o objeto JSON purificado.

Constraint: Nunca gerar um campo sem o mapeamento de obrigatoriedade (ID 8).

Habilidade: TableExpander
Input: Número de colunas e linhas extraídas de uma imagem/PDF.

Ação: Criar uma estrutura de repetição que gera componentes alinhados milimetricamente, calculando o Y incremental para evitar sobreposição.

13. Conclusão da Visão de Engenharia
O projeto Antigravity não busca ser um "editor bonitinho". Ele busca ser uma Ferramenta de Poder. Ao final, o Francisco terá em mãos um sistema onde ele pode:

Arrastar um PDF de um protocolo médico.

Ver o sistema "ler" o PDF e criar 80% do formulário sozinho.

Ajustar as regras de negócio via código C#.

Clicar em "Gerar" e obter um arquivo pronto para importar no MV, sem erros de layout ou de banco.