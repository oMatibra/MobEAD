# Execute com PowerShell 5.1 ou 7, apos terraform apply.
$ErrorActionPreference = 'Stop'
$projeto = Split-Path -Parent $PSScriptRoot
$terraformDir = Join-Path $projeto 'terraform'
$destino = Join-Path $projeto 'ansible\inventory.ini'

Push-Location $terraformDir
try {
    $ip = (& terraform output -raw ip_publico 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $ip -notmatch '^\d{1,3}(\.\d{1,3}){3}$') {
        throw "Nao foi possivel obter o IP publico. Confira se 'terraform apply' terminou com sucesso. Saida: $ip"
    }
} finally {
    Pop-Location
}

$conteudo = @"
[windows]
windows2019 ansible_host=$ip

[windows:vars]
ansible_user=Administrator
ansible_connection=winrm
ansible_port=5986
ansible_winrm_scheme=https
ansible_winrm_transport=basic
ansible_winrm_server_cert_validation=ignore
ansible_winrm_operation_timeout_sec=60
ansible_winrm_read_timeout_sec=70
"@

Set-Content -Path $destino -Value $conteudo -Encoding Ascii
Write-Host "Inventario criado: $destino" -ForegroundColor Green
Write-Host "Servidor: $ip" -ForegroundColor Green
