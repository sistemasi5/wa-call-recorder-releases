# Atualiza o WA Call Recorder ja instalado, sem baixar pasta nenhuma.
# Uso (Windows + R):
#   powershell -ep bypass -c "irm https://raw.githubusercontent.com/sistemasi5/wa-call-recorder-releases/main/atualizar.ps1|iex"
# Mantem config.toml, .env, settings.json, gravacoes (queue) e logs. Depois disso o
# programa passa a se atualizar sozinho (launcher + releases do GitHub).
# Texto sem acento de proposito: irm|iex nao garante a codificacao do arquivo.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$repo = 'sistemasi5/wa-call-recorder-releases'
$ua = @{ 'User-Agent' = 'wa-call-recorder-atualizar' }
$tmp = $null
try {
    Write-Host ''
    Write-Host 'Atualizando o WA Call Recorder... (leva menos de um minuto)'
    $dir = Join-Path $env:LOCALAPPDATA 'WA Call Recorder'
    if (-not (Test-Path (Join-Path $dir '.env'))) {
        throw 'O WA Call Recorder nao esta instalado neste computador.'
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $rel = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest" -Headers $ua

    $tmp = Join-Path $env:TEMP ('wacr-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    $files = @{
        'instalador.exe'           = 'Instalar WA Call Recorder.exe'
        'launcher.exe'             = 'WA Call Recorder.exe'
        'config.example.toml'      = 'config.example.toml'
        'wa-call-recorder-win.zip' = 'agente.zip'
    }
    foreach ($name in $files.Keys) {
        $asset = $rel.assets | Where-Object { $_.name -eq $name }
        if (-not $asset) { throw "arquivo $name nao encontrado na versao $($rel.tag_name)" }
        Invoke-WebRequest $asset.browser_download_url -OutFile (Join-Path $tmp $files[$name]) -UseBasicParsing -Headers $ua
    }
    Expand-Archive -Path (Join-Path $tmp 'agente.zip') -DestinationPath (Join-Path $tmp 'WA Call Recorder') -Force

    & (Join-Path $tmp 'Instalar WA Call Recorder.exe') --silent | Out-Null
    $log = Get-Content (Join-Path $tmp 'install-log.txt') -Raw -ErrorAction SilentlyContinue
    if (-not $log -or $log -match 'ERRO') { throw "a instalacao nao terminou:`n$log" }

    Write-Host ''
    Write-Host "Pronto! WA Call Recorder atualizado ($($rel.tag_name))."
    Write-Host 'A partir de agora ele se atualiza sozinho. Pode fechar esta janela.'
    Start-Sleep -Seconds 8
}
catch {
    Write-Host ''
    Write-Host "ERRO: $_" -ForegroundColor Red
    Write-Host 'Tire um print desta janela e mande para quem administra o sistema.'
    Read-Host 'Pressione Enter para fechar'
}
finally {
    if ($tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}
