# ================================
# Resolve-Internet
# Author: Aayush
# Requires: Admin
# ================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---- Admin check ----
if (-not ([Security.Principal.WindowsPrincipal]
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Script must be run as Administrator." -ForegroundColor Red
    exit 1
}

# ---- Logging ----
$LogFile = "$env:TEMP\Resolve-Internet.log"
Start-Transcript -Path $LogFile -Append

Write-Host "=== Resolve Internet Connectivity (Hardened) ===" -ForegroundColor Cyan

try {
    # ---- Detect active adapter ----
    $adapter = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1
    if (-not $adapter) { throw "No active network adapter found." }

    Write-Host "Adapter: $($adapter.Name)" -ForegroundColor Green

    # ---- Gateway check ----
    $gateway = (Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex).
                IPv4DefaultGateway.NextHop

    if ($gateway -and -not (Test-Connection $gateway -Count 2 -Quiet)) {
        Write-Host "Gateway unreachable. Resetting adapter..." -ForegroundColor Yellow
        Disable-NetAdapter -Name $adapter.Name -Confirm:$false
        Start-Sleep 5
        Enable-NetAdapter -Name $adapter.Name -Confirm:$false
        Start-Sleep 10
    }

    # ---- DHCP renew ----
    Write-Host "Renewing IP configuration..."
    ipconfig /release | Out-Null
    ipconfig /renew | Out-Null

    # ---- DNS validation ----
    if (-not (Resolve-DnsName google.com -ErrorAction SilentlyContinue)) {
        Write-Host "DNS failure detected. Resetting DNS..." -ForegroundColor Yellow
        ipconfig /flushdns | Out-Null
        Set-DnsClientServerAddress `
            -InterfaceIndex $adapter.ifIndex `
            -ServerAddresses ("8.8.8.8","8.8.4.4")
    }

    # ---- Internet test ----
    if (-not (Test-Connection 8.8.8.8 -Count 2 -Quiet)) {
        Write-Host "Deep network reset required." -ForegroundColor Red
        netsh winsock reset | Out-Null
        netsh int ip reset | Out-Null
        Write-Host "Reboot recommended." -ForegroundColor Yellow
    } else {
        Write-Host "Internet connectivity restored." -ForegroundColor Green
    }
}
catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Stop-Transcript
    Write-Host "Log saved to $LogFile" -ForegroundColor Cyan
}

