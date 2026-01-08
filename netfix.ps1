# ==========================================
# Network Health Check (User-Friendly Mode)
# Version: 3.0 (Hybrid Diagnostic)
# Author: Aayush Acharya
# ==========================================

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

Clear-Host
Write-Host "=== Network Health Monitor v3.0 ===" -ForegroundColor Cyan
if ($isAdmin) { Write-Host "[MODE] Administrator (Auto-Fix Enabled)" -ForegroundColor Green }
else { Write-Host "[MODE] Standard User (Read-Only Diagnostic)" -ForegroundColor Yellow }
Write-Host "---------------------------------------------------"

# --- STEP 1: Find Adapter ---
$adapter = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

if (!$adapter) {
    Write-Host "[CRITICAL] No active network cable/Wi-Fi found." -ForegroundColor Red
    Exit
}
Write-Host "[INFO] Adapter: $($adapter.Name)" -ForegroundColor Gray

# --- STEP 2: Gateway Check ---
$gateway = (Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex).IPv4DefaultGateway.NextHop
if ($gateway) {
    if (Test-Connection -ComputerName $gateway -Count 1 -Quiet) {
        Write-Host "[OK] Gateway Reachable" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Gateway Unreachable" -ForegroundColor Red
        if ($isAdmin) {
            Write-Host "   > [FIX] Resetting Adapter..." -ForegroundColor Yellow
            Disable-NetAdapter -Name $adapter.Name -Confirm:$false; Start-Sleep 2; Enable-NetAdapter -Name $adapter.Name -Confirm:$false
        } else {
            Write-Host "   > [SKIP] Cannot reset adapter (Admin Rights Required)." -ForegroundColor DarkGray
        }
    }
}

# --- STEP 3: DNS Check ---
if (Resolve-DnsName google.com -ErrorAction SilentlyContinue) {
    Write-Host "[OK] DNS Resolution" -ForegroundColor Green
} else {
    Write-Host "[FAIL] DNS Not Resolving" -ForegroundColor Red
    if ($isAdmin) {
        Write-Host "   > [FIX] Switching to Google DNS (8.8.8.8)..." -ForegroundColor Yellow
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("8.8.8.8")
    } else {
        Write-Host "   > [SKIP] Cannot change DNS (Admin Rights Required)." -ForegroundColor DarkGray
    }
}

# --- STEP 4: Internet Check ---
if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet) {
    Write-Host "`n[SUCCESS] You are Online." -ForegroundColor Cyan
} else {
    Write-Host "`n[FAIL] No Internet Access." -ForegroundColor Red
    if (!$isAdmin) {
        Write-Host "TIP: Right-click this script and select 'Run as Administrator' to attempt auto-repair." -ForegroundColor Yellow
    }
}
Read-Host "Press Enter to exit..."
