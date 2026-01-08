# ================================
# Automated Internet Troubleshooter
# Run as Administrator
# ================================

Write-Host "=== Internet Connectivity Troubleshooter ===" -ForegroundColor Cyan

# Get active network adapter
$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

if (!$adapter) {
    Write-Host "No active network adapter found." -ForegroundColor Red
    exit
}

Write-Host "Active Adapter: $($adapter.Name)" -ForegroundColor Green

# Test default gateway
$gateway = (Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex).IPv4DefaultGateway.NextHop

if ($gateway) {
    Write-Host "Testing gateway connectivity ($gateway)..."
    if (Test-Connection -ComputerName $gateway -Count 2 -Quiet) {
        Write-Host "Gateway reachable." -ForegroundColor Green
    } else {
        Write-Host "Gateway NOT reachable. Resetting adapter..." -ForegroundColor Yellow
        Disable-NetAdapter -Name $adapter.Name -Confirm:$false
        Start-Sleep -Seconds 5
        Enable-NetAdapter -Name $adapter.Name -Confirm:$false
        Start-Sleep -Seconds 10
    }
} else {
    Write-Host "No default gateway detected. Renewing IP..." -ForegroundColor Yellow
}

# Renew IP
Write-Host "Renewing IP address..."
ipconfig /release | Out-Null
ipconfig /renew | Out-Null

# DNS test
Write-Host "Testing DNS resolution..."
if (Resolve-DnsName google.com -ErrorAction SilentlyContinue) {
    Write-Host "DNS working correctly." -ForegroundColor Green
} else {
    Write-Host "DNS issue detected. Resetting DNS..." -ForegroundColor Yellow
    ipconfig /flushdns | Out-Null
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("8.8.8.8","8.8.4.4")
}

# Internet test
Write-Host "Testing external internet access..."
if (Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet) {
    Write-Host "Internet connectivity confirmed." -ForegroundColor Green
} else {
    Write-Host "Internet still unreachable. Performing deep reset..." -ForegroundColor Red

    netsh winsock reset | Out-Null
    netsh int ip reset | Out-Null

    Write-Host "System reboot recommended to complete repairs." -ForegroundColor Yellow
}

Write-Host "=== Troubleshooting Completed ===" -ForegroundColor Cyan
