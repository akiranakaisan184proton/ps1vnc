# Script para instalação e configuração do TightVNC sem depender de vncpasswd.exe
# Autor: AI Chat (ajustado com correções baseadas em docs oficiais)

# Parâmetros de configuração
$installerUrl = "https://www.tightvnc.com/download/2.8.85/tightvnc-2.8.85-gpl-setup-64bit.msi"
$installerPath = "$env:TEMP\tightvnc.msi"
$senhaVNC = 123456  # Senha em texto plano, máximo 8 caracteres (altere aqui)
$portaVNC = 5900

# Função para baixar o instalador
function Baixar-Instalador {
    Write-Host "Baixando o instalador..."
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
}

# Função para instalar e configurar silenciosamente via MSI properties
function Instalar-TightVNC {
    Write-Host "Instalando e configurando TightVNC..."

    # Para o serviço se já existir (para reinstalações)
    Stop-Service -Name "tvnserver" -Force -ErrorAction SilentlyContinue

    # Argumentos do msiexec com configurações (senha em texto plano!)
    $arguments = "/i `"$installerPath`" /quiet /norestart " +
                 "ADDLOCAL=Server,Viewer " +
                 "SERVER_REGISTER_AS_SERVICE=1 " +
                 "SERVER_ADD_FIREWALL_EXCEPTION=1 " +
                 "SET_USEVNCAUTHENTICATION=1 " +
                 "VALUE_OF_USEVNCAUTHENTICATION=1 " +
                 "SET_PASSWORD=1 " +
                 "VALUE_OF_PASSWORD=$senhaVNC " +
                 "SET_RFBPORT=1 " +
                 "VALUE_OF_RFBPORT=$portaVNC " +
                 "SET_ALLOWLOOPBACK=1 " +
                 "VALUE_OF_ALLOWLOOPBACK=1 " +
                 "SET_LOOPBACKONLY=1 " +
                 "VALUE_OF_LOOPBACKONLY=0"

    Start-Process msiexec.exe -ArgumentList $arguments -Wait

    # Inicia o serviço após instalação
    Start-Service -Name "tvnserver" -ErrorAction SilentlyContinue
}

# Execução
try {
    Baixar-Instalador
    Instalar-TightVNC
    Write-Host "Configuração concluída! Reinicie o computador se necessário."
}
catch {
    Write-Host "Erro durante a execução: $_"
}

# Verificação pós-instalação (opcional, para depuração)
Write-Host "Verificando serviço:"
Get-Service -Name "tvnserver"
Write-Host "Teste a porta local: Test-NetConnection -ComputerName localhost -Port $portaVNC"