@echo off
setlocal
echo ==========================================
echo    Programa de Conversao - Replica MV
echo ==========================================
echo.
echo Iniciando a transformacao dos arquivos...
echo.

:: O comando abaixo aciona o motor de conversao
:: Caminho da Entrada: Entrada
:: Caminho da Saida: Saida
python src/cli/cli_mass_converter.py --input Entrada --output Saida

echo.
echo ==========================================
echo    Processo concluido com sucesso!
echo    Seus arquivos estao na pasta "Saida".
echo ==========================================
echo.
pause
