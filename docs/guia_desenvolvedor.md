# Guia do Desenvolvedor: Projeto Réplica MV

## 1. Objetivo
Este guia protege a integridade clínica e a compatibilidade com o legado MV.
**Este projeto é FAIL-FAST por design.**

## 2. Execução Obrigatória
Nenhum commit ou modificação de lógica deve ser aceito sem integridade total.
Sempre execute a esteira de testes centralizada:
- `python run_all_tests.py`
**Se qualquer teste falhar: PARE, CORRIJA, REEXECUTE.**

---

## 3. Decisões de Arquitetura (ADRs)

### ADR-001: A Regra da Tabela (Hashes Estáticos)
- **Regra**: Nunca compute MD5 em tempo real para o caminho crítico. Sempre use a Look-up Table (`tabela_hashes.py`).
- **Por quê**: Evita overhead de CPU em ambientes Citrix/MV e garante previsibilidade de latência.
- **Falha Típica**: Lentidão intermitente e timeouts em processamentos em lote.
- **Impacto no MV**: Atraso na carga de documentos e gargalos no MV Report.
- **Validação**: Verificado em `test_onda2.py`.

### ADR-002: A Regra do Inspetor (Regex Fail-Fast)
- **Regra**: Obrigatório explodir exceção fatal para IDs fora do padrão. Nunca use apenas "warnings".
- **Por quê**: O legado MV rejeita silenciosamente entradas inválidas, causando corrupção operacional indetectável.
- **Falha Típica**: Importação parcial onde o dado parece existir, mas está inacessível.
- **Impacto no MV**: Inconsistência clínica e perda de rastreabilidade de auditoria.
- **Validação**: Verificado em `test_onda5.py` (Circuit Breaker).

### ADR-003: A Regra da Caixa Preta (Serialização Tardia)
- **Regra**: Nunca serialize layout antecipadamente. Mantenha os dados em "gavetas abertas" (objetos) até o último momento.
- **Por quê**: Protege a memória do parser do sistema alvo contra crashes geométricos.
- **Falha Típica**: Consumo excessivo de memória (Memory Leak/Crash) e impossibilidade de saneamento tardio.
- **Impacto no MV**: Falha total no import de documentos complexos.
- **Validação**: Verificado em `test_onda4.py`.
