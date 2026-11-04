$ErrorActionPreference = 'Stop'
$projeto = Split-Path -Parent $PSScriptRoot
Push-Location (Join-Path $projeto 'terraform')
try {
    $ip = (& terraform output -raw ip_publico 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $ip -notmatch '^\d{1,3}(\.\d{1,3}){3}$') {
        throw 'Instancia ainda nao provisionada. Execute terraform apply primeiro.'
    }
} finally {
    Pop-Location
}

foreach ($porta in @(3389, 5986, 80)) {
    $resultado = Test-NetConnection -ComputerName $ip -Port $porta -WarningAction SilentlyContinue
    [PSCustomObject]@{
        Endereco = $ip
        Porta = $porta
        Acessivel = $resultado.TcpTestSucceeded
    }
}
