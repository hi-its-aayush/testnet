# ==========================================
# Network Health Monitor v4.0 (DHCP Enforcer)
# Author: Aayush Acharya
# ==========================================

# Check Admin Rights (REQUIRED for DHCP Reset)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

Clear-Host
Write-Host "=== NETWORK REPAIR TOOL v4.0 ===" -ForegroundColor Cyan
if (!$isAdmin) { Write-Host "[WARNING] Run as Administrator to unlock repairs." -ForegroundColor Red }

# --- STEP 1: Find Adapter ---
$adapter = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

if (!$adapter) { Write-Host "[CRITICAL] No Cable/Wi-Fi Connected!" -ForegroundColor Red; Exit }
Write-Host "[INFO] Adapter: $($adapter.Name)" -ForegroundColor Green

# --- STEP 2: Connectivity Check ---
Write-Host "Testing Connection..." -NoNewline
if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet) {
    Write-Host " [ONLINE]" -ForegroundColor Green
    Write-Host "`n[SUCCESS] System Operational." -ForegroundColor Cyan
    Exit # Stop if everything works
} else {
    Write-Host " [OFFLINE]" -ForegroundColor Red
}

# --- STEP 3: The "Nuclear" DHCP Reset ---
if ($isAdmin) {
    Write-Host "`n[ACTION] Detecting Bad Static Config..." -ForegroundColor Yellow
    
    try {
        # 1. Force IP to "Obtain Automatically" (DHCP)
        Write-Host "   > Resetting IP to DHCP (Automatic)..." -NoNewline
        Set-NetIPInterface -InterfaceIndex $adapter.ifIndex -Dhcp Enabled -ErrorAction Stop
        Write-Host " [DONE]" -ForegroundColor Green

        # 2. Force DNS to "Obtain Automatically" (Clears bad statics)
        Write-Host "   > Resetting DNS to DHCP (Automatic)..." -NoNewline
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses -ErrorAction Stop
        Write-Host " [DONE]" -ForegroundColor Green

        # 3. Renew the new Automatic Lease
        Write-Host "   > Getting new IP Address..." -NoNewline
        ipconfig /renew | Out-Null
        Write-Host " [DONE]" -ForegroundColor Green
        
    } catch {
        Write-Host "`n[ERROR] Could not reset adapter: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "`n[SKIP] Cannot force DHCP Reset without Admin rights." -ForegroundColor DarkGray
}

# --- STEP 4: Final Verification ---
Write-Host "`nVerifying Fix..." -NoNewline
if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet) {
    Write-Host " [SUCCESS] Internet Restored!" -ForegroundColor Green -BackgroundColor Black
} else {
    Write-Host " [FAILED] Still Offline. Reboot Router." -ForegroundColor Red
}

Read-Host "Press Enter to exit..."
