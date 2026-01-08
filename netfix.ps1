# ==========================================
# Network Health Monitor v3.2
# Author: Aayush Acharya
# ==========================================

# Check Admin Rights
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

Clear-Host
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "   NETWORK OPERATIONS CENTER (NOC) TOOL    " -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "User: $env:USERNAME" -ForegroundColor Gray
Write-Host "Time: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
if ($isAdmin) { Write-Host "[ACCESS] ELEVATED (Admin)" -ForegroundColor Green }
else { Write-Host "[ACCESS] READ-ONLY (User)" -ForegroundColor Yellow }
Write-Host "-------------------------------------------`n"

# --- STEP 1: Hardware Scan ---
Write-Host "Step 1: Scanning Hardware..." -ForegroundColor Cyan
$adapter = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

if ($adapter) {
    Write-Host "   [FOUND] $($adapter.Name)" -ForegroundColor Green
    Write-Host "   [SPEED] $($adapter.LinkSpeed)" -ForegroundColor Gray
} else {
    Write-Host "   [CRITICAL] No Cable/Wi-Fi Connected!" -ForegroundColor Red
    Exit
}

# --- STEP 2: Gateway Analysis (Fixed Null Error) ---
Write-Host "`nStep 2: Analyzing Gateway..." -ForegroundColor Cyan
$ipConfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex
$gateway = $ipConfig.IPv4DefaultGateway.NextHop

if ([string]::IsNullOrWhiteSpace($gateway)) {
    Write-Host "   [FAIL] No Gateway Address Found!" -ForegroundColor Red
    $gatewayStatus = "Down"
} else {
    Write-Host "   [GATE ] $gateway" -ForegroundColor Yellow
    if (Test-Connection -ComputerName $gateway -Count 1 -Quiet) {
        Write-Host "   [STATUS] Gateway Reachable" -ForegroundColor Green
        $gatewayStatus = "Up"
    } else {
        Write-Host "   [FAIL] Gateway Unreachable" -ForegroundColor Red
        $gatewayStatus = "Down"
    }
}

# --- REPAIR LOGIC 1: Gateway/Adapter Reset ---
if ($gatewayStatus -eq "Down" -and $isAdmin) {
    Write-Host "   [ACTION] Resetting Adapter Hardware..." -ForegroundColor Magenta
    Disable-NetAdapter -Name $adapter.Name -Confirm:$false
    Start-Sleep -Seconds 2
    Enable-NetAdapter -Name $adapter.Name -Confirm:$false
    Start-Sleep -Seconds 5
    Write-Host "   [DONE] Adapter Reset Complete." -ForegroundColor Green
}

# --- STEP 3: DNS Check ---
Write-Host "`nStep 3: Checking DNS Services..." -ForegroundColor Cyan
$dnsWorking = Resolve-DnsName google.com -ErrorAction SilentlyContinue

if ($dnsWorking) {
    Write-Host "   [OK] Resolution Functional" -ForegroundColor Green
} else {
    Write-Host "   [FAIL] DNS Broken" -ForegroundColor Red
    
    # --- REPAIR LOGIC 2: DNS Flush ---
    if ($isAdmin) {
        Write-Host "   [ACTION] Flushing DNS Cache..." -ForegroundColor Magenta
        ipconfig /flushdns | Out-Null
        Write-Host "   [ACTION] Forcing Google DNS (8.8.8.8)..." -ForegroundColor Magenta
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("8.8.8.8","1.1.1.1")
        Write-Host "   [DONE] DNS Configuration Patched." -ForegroundColor Green
    }
}

# --- STEP 4: Final Verification ---
Write-Host "`nStep 4: Verifying Internet Access..." -ForegroundColor Cyan
Start-Sleep -Seconds 2 # Give repairs time to kick in

if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet) {
    Write-Host "   [ONLINE] Connection Established." -ForegroundColor Green
    
    Write-Host "`n===========================================" -ForegroundColor Cyan
    Write-Host "   SYSTEM STATUS: OPERATIONAL              " -ForegroundColor Black -BackgroundColor Green
    Write-Host "===========================================" -ForegroundColor Cyan
} else {
    Write-Host "   [OFFLINE] Repairs Failed or Cable Unplugged." -ForegroundColor Red
    
    Write-Host "`n===========================================" -ForegroundColor Cyan
    Write-Host "   SYSTEM STATUS: CRITICAL FAILURE         " -ForegroundColor White -BackgroundColor Red
    Write-Host "===========================================" -ForegroundColor Cyan
}

Read-Host "Press Enter to exit..."
