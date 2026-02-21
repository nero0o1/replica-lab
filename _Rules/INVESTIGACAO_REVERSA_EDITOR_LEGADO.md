# Investigação Reversa: Editor Legado (Editor 2)

**Objetivo:** Decompor o formato de exportação oficial do MV Editor 2 para permitir a leitura e conversão para a nova AST neutra.

## Formato Identificado (XML .edt)
Diferente das extrações brutas de banco de dados (`tempfile*.txt`), o formato oficial de exportação do Editor 2 consiste em arquivos `.edt` estruturados em XML.

### Características do Formato:
- **Encoding:** UTF-8.
- **Estrutura:** Baseada em tags `<editor>`, `<item>`, `<data>` e `<children>`.
- **Delimitadores:** Tags XML padrão e blocos `<![CDATA[...]]>` para conteúdos complexos (SQL, scripts).
- **Dados Binários:** Podem conter definições de JasperReports embutidas ou referências a blobs.

## Plano de Deconstrução (Ajustado)
1. **Tokenização:** Utilizar parser XML nativo para navegar pela árvore de componentes.
2. **Isolamento de Cargas:** Extrair propriedades de metadados e lógica de negócio de cada tag `<item>`.
3. **Mapeamento:** Converter a hierarquia XML para as classes `MvField` e `MvProperty` da nossa AST neutra.
4. **Tratamento de Jasper:** Identificar e isolar blocos de relatório para processamento futuro pelo Jasper Scrubber.

## Próximos Passos
- Implementar `parser_legado.py` focado no XML `.edt`.
- Validar a extração de propriedades críticas (Ações, Regras, Máscaras).
