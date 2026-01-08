# ==========================================
# Automated Internet Connectivity Fixer
# Version: 2.0 (Enterprise Grade)
# Author: Aayush Acharya
# ==========================================

# --- STEP 1: Auto-Elevate to Administrator ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Script needs Admin rights to reset adapters."
    Write-Host "Elevating now..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Clear-Host
Write-Host "=== Internet Connectivity Troubleshooter v2.0 ===" -ForegroundColor Cyan
Write-Host "Run by: $env:USERNAME on $(Get-Date)" -ForegroundColor DarkGray
Write-Host "---------------------------------------------------"

# --- STEP 2: Intelligent Adapter Selection ---
# Filter allows only PHYSICAL adapters that are connected. Ignores Virtual/VPN adapters.
$adapter = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

if (!$adapter) {
    Write-Host "[CRITICAL] No active PHYSICAL network adapter found." -ForegroundColor Red
    Write-Host "Check if your Wi-Fi button is off or cable is unplugged."
    Exit
}

Write-Host "[INFO] Active Adapter Found: " -NoNewline; Write-Host "$($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Green

# --- STEP 3: Gateway & Connectivity Check ---
$gateway = (Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex).IPv4DefaultGateway.NextHop

if ($gateway) {
    Write-Host "[TEST] Pinging Gateway ($gateway)..." -NoNewline
    if (Test-Connection -ComputerName $gateway -Count 2 -Quiet) {
        Write-Host " [OK]" -ForegroundColor Green
    } else {
        Write-Host " [FAILED]" -ForegroundColor Red
        Write-Host "[ACTION] Gateway unreachable. Resetting Adapter hardware..." -ForegroundColor Yellow
        
        try {
            Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
            Write-Host "       > Adapter Disabled." -ForegroundColor DarkGray
            Start-Sleep -Seconds 3
            Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
            Write-Host "       > Adapter Enabled. Waiting for handshake..." -ForegroundColor DarkGray
            Start-Sleep -Seconds 10
        } catch {
            Write-Host "[ERROR] Failed to reset adapter: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "[WARN] No Default Gateway detected." -ForegroundColor Yellow
}

# --- STEP 4: IP Stack Refresh ---
Write-Host "[ACTION] Refreshing IP Configuration..." -ForegroundColor Cyan
Invoke-Command { ipconfig /release } | Out-Null
Invoke-Command { ipconfig /renew } | Out-Null
Write-Host "       > IP Renewed." -ForegroundColor Green

# --- STEP 5: DNS Health Check ---
Write-Host "[TEST] Testing DNS Resolution..." -NoNewline
if (Resolve-DnsName google.com -ErrorAction SilentlyContinue) {
    Write-Host " [OK]" -ForegroundColor Green
} else {
    Write-Host " [FAILED]" -ForegroundColor Red
    Write-Host "[ACTION] DNS failing. Switching to Google Public DNS (8.8.8.8)..." -ForegroundColor Yellow
    try {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("8.8.8.8","1.1.1.1")
        ipconfig /flushdns | Out-Null
        Write-Host "       > DNS Updated & Flushed." -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Could not set DNS: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- STEP 6: Final Connectivity Verification ---
Write-Host "[TEST] verifying Internet Access..." -NoNewline
if (Test-Connection -ComputerName 8.8.8.8 -Count 2 -Quiet) {
    Write-Host " [ONLINE]" -ForegroundColor Green
    Write-Host "`n[SUCCESS] Internet connectivity restored." -ForegroundColor Cyan
} else {
    Write-Host " [OFFLINE]" -ForegroundColor Red
    Write-Host "`n[ACTION] Deep Network Reset required (Winsock/IP Reset)..." -ForegroundColor Magenta
    
    Start-Process -FilePath "netsh" -ArgumentList "winsock reset" -WindowStyle Hidden
    Start-Process -FilePath "netsh" -ArgumentList "int ip reset" -WindowStyle Hidden
    
    Write-Host "[REQUIRED] A System Reboot is required to finish repairs." -ForegroundColor Red -BackgroundColor Yellow
}

Write-Host "`n=== Troubleshooting Completed ===" -ForegroundColor Cyan
Read-Host "Press Enter to exit..."
