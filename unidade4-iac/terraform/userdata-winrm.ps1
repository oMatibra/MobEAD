<powershell>
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Executado automaticamente no primeiro boot pelo EC2Launch.
# A configuracao do IIS e realizada DEPOIS pelo playbook Ansible.
New-Item -Path 'C:\Temp' -ItemType Directory -Force | Out-Null
Start-Transcript -Path 'C:\Temp\unidade4-winrm-setup.log' -Append

try {
    Set-Service -Name WinRM -StartupType Automatic
    Start-Service -Name WinRM
    Enable-PSRemoting -Force -SkipNetworkProfileCheck

    # Autenticacao Basic SOMENTE sobre WinRM com HTTPS (5986).
    Set-Item -Path 'WSMan:\localhost\Service\Auth\Basic' -Value $true
    Set-Item -Path 'WSMan:\localhost\Service\AllowUnencrypted' -Value $false

    $httpsListeners = @(Get-ChildItem -Path 'WSMan:\localhost\Listener' |
        Where-Object { $_.Keys -contains 'Transport=HTTPS' })

    if ($httpsListeners.Count -eq 0) {
        $cert = New-SelfSignedCertificate `
            -DnsName $env:COMPUTERNAME `
            -CertStoreLocation 'Cert:\LocalMachine\My' `
            -KeyAlgorithm RSA `
            -KeyLength 2048 `
            -HashAlgorithm SHA256 `
            -NotAfter (Get-Date).AddYears(1)

        New-Item -Path 'WSMan:\localhost\Listener' `
            -Address '*' `
            -Transport HTTPS `
            -CertificateThumbprint $cert.Thumbprint `
            -Force | Out-Null
    }

    $firewallRule = Get-NetFirewallRule -DisplayName 'UNIDADE4 - WinRM HTTPS 5986' -ErrorAction SilentlyContinue
    if (-not $firewallRule) {
        New-NetFirewallRule `
            -DisplayName 'UNIDADE4 - WinRM HTTPS 5986' `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort 5986 `
            -Action Allow `
            -Profile Any | Out-Null
    }

    Write-Output 'UNIDADE4: WinRM HTTPS configurado na porta 5986.'
    winrm enumerate winrm/config/listener
} finally {
    Stop-Transcript
}
</powershell>
