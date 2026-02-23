# Dicionário de Dados — Etiquetas Semânticas

Este documento registra a tradução formal de **IDs numéricos legados** (magic numbers) para **etiquetas nominais descritivas**, conforme implementado no módulo `src/core/etiquetas_semanticas.py`.

---

## 1. Motivação

O sistema legado MV (Editor 2) utiliza IDs numéricos inteiros para identificar propriedades de campo nos formulários clínicos. Esses números são armazenados em colunas Oracle como `CD_PROPRIEDADE` e propagados pelo XML sem nenhum significado semântico visível.

**Problema**: Um desenvolvedor lendo `CD_PROPRIEDADE = 8` não tem como saber que isso significa "campo obrigatório" sem consultar o banco de dados ou documentação externa. Isso gera:

- **Fragilidade**: Erros por confusão entre IDs semelhantes.
- **Custo cognitivo**: Necessidade de consultar tabelas externas a cada alteração.
- **Risco de regressão**: Substituições incorretas em refatorações.

**Solução**: Criação de um módulo central (`EtiquetasSemanticas`) que atua como **ponto único de verdade**, eliminando magic numbers de todo o código Python.

---

## 2. Tabela de Tradução Completa

| ID Legado | Etiqueta Semântica          | Tipo     | Descrição no Domínio Clínico                                                  |
| :-------: | :-------------------------- | :------- | :---------------------------------------------------------------------------- |
| 1         | `tamanho`                   | Integer  | Tamanho máximo de caracteres permitido no campo.                              |
| 2         | `lista_valores`             | Array    | Lista de opções para campos do tipo ComboBox/Radio.                           |
| 3         | `mascara`                   | String   | Máscara de formatação de entrada (ex: `###.###.###-##` para CPF).             |
| 4         | `acao`                      | String   | Script de ação/trigger legado associado ao campo (cuidado: SQL bruto).        |
| 5         | `usado_em`                  | String   | Referência cruzada: em quais contextos este campo é utilizado.                |
| **7**     | **`editavel`**              | Boolean  | Define se o campo aceita entrada do usuário ou é somente leitura.             |
| **8**     | **`obrigatorio`**           | Boolean  | Define se o preenchimento do campo é mandatório para salvar o formulário.     |
| 9         | `valor_inicial`             | String   | Valor padrão (default) preenchido automaticamente na abertura do formulário.  |
| 10        | `criado_por`                | String   | Identificador do usuário ou sistema que criou o campo.                        |
| 13        | `acao_texto_padrao`         | String   | Ação que gera o texto padrão automaticamente.                                 |
| 14        | `texto_padrao`              | String   | Texto pré-configurado inserido ao abrir o formulário.                         |
| 15        | `parametros_texto_padrao`   | String   | Parâmetros para a geração do texto padrão.                                    |
| **17**    | **`reprocessar`**           | Boolean  | Flag que indica se o campo deve ser reprocessado ao salvar/recarregar.        |
| 18        | `lista_icones`              | Array    | Ícones associados às opções da lista de valores.                              |
| 21        | `acaoSql`                   | String   | Query SQL de ação direta (Oracle). **Cuidado: campo sensível.**               |
| 22        | `regras_usadas`             | String   | Referência às regras comportamentais que afetam este campo.                   |
| 23        | `voz`                       | Boolean  | Habilita/desabilita reconhecimento de voz para o campo.                       |
| 29        | `expor_para_api`            | Boolean  | Define se o campo deve ser exposto em endpoints REST/API.                     |
| 30        | `hint`                      | String   | Texto de dica exibido como placeholder/tooltip para o usuário.                |
| 31        | `descricaoApi`              | String   | Descrição técnica do campo para documentação de API.                          |
| 33        | `importado`                 | Boolean  | Flag indicando se o campo foi importado de outro documento.                   |
| 34        | `migrado`                   | Boolean  | Flag indicando se o campo foi migrado do Editor 2 para o Editor 3.            |
| 35        | `tipo_do_grafico`           | String   | Tipo de gráfico associado ao campo (barras, pizza, etc).                      |
| 36        | `requisicao_api`            | String   | Configuração de requisição à API externa vinculada ao campo.                  |
| **38**    | **`cascata_de_regra`**      | Boolean  | Bit de terminação de reentrância. Sem ele, regras causam recursão infinita.   |

> **Nota**: As linhas em negrito representam os IDs de maior criticidade operacional para o sistema.

---

## 3. Módulo Central: `etiquetas_semanticas.py`

- **Localização**: `src/core/etiquetas_semanticas.py`
- **Enum**: `PropId` — cada membro é um `IntEnum` com valor = ID legado.
- **Dicionários**:
  - `ID_PARA_ETIQUETA`: `Dict[int, str]` — traduz `8 → "obrigatorio"`.
  - `ETIQUETA_PARA_ID`: `Dict[str, int]` — traduz `"obrigatorio" → 8`.
- **Funções utilitárias**:
  - `obter_etiqueta(prop_id: int) → str`
  - `obter_id(etiqueta: str) → Optional[int]`

---

## 4. Paridade com PowerShell

O módulo `RosettaStone.ps1` já continha mapeamentos equivalentes (`$Map`, `$RevMap`). A criação de `etiquetas_semanticas.py` garante paridade entre os dois runtimes:

| Conceito                 | PowerShell (`RosettaStone.ps1`)  | Python (`etiquetas_semanticas.py`)  |
| :----------------------- | :------------------------------- | :---------------------------------- |
| ID → Etiqueta            | `[RosettaStone]::GetIdentifier()` | `obter_etiqueta()`                 |
| Etiqueta → ID            | `[RosettaStone]::GetId()`         | `obter_id()`                       |
| Enum / Constantes        | Chaves no `$Map` hashtable        | `PropId` (IntEnum)                 |

---

## 5. Arquivos Refatorados

| Arquivo                             | Tipo de Alteração                                                                                   |
| :----------------------------------- | :-------------------------------------------------------------------------------------------------- |
| `src/core/etiquetas_semanticas.py`  | **CRIADO** — Módulo central de tradução (Enum + dicionários bidirecionais).                         |
| `src/core/ast_nodes.py`             | Import de `PropId`. Comentário `(ID 38)` substituído por `(PropId.CASCATA_DE_REGRA = 38)`.          |
| `src/core/json_serializer.py`       | Propriedades agora exportadas com etiquetas semânticas em vez de IDs numéricos.                     |
| `src/core/json_parser.py`           | Parser reconhece tanto chaves numéricas (legado) quanto etiquetas semânticas (moderno).             |
| `src/core/xml_parser.py`            | `_parse_property` agora preenche `identifier` via `obter_etiqueta()` ao invés de string vazia.      |
| `src/Drivers/DriverV3.ps1`          | Comentário `(IDs 4, 21)` substituído por `(acao=4, acaoSql=21)` para auto-documentação.            |

---

*Gerado em: 2026-02-22 | Agente de Refatoração de Código*
