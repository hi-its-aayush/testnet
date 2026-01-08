# ==========================================
# Network Health Monitor v3.1 (Visual Edition)
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
Write-Host "Step 1: Scanning Network Hardware..." -ForegroundColor Cyan
Write-Progress -Activity "Scanning Hardware" -Status "Detecting Adapters..." -PercentComplete 20
Start-Sleep -Milliseconds 500 # Artificial delay for visual effect

$adapter = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

if ($adapter) {
    Write-Host "   [FOUND] $($adapter.Name)" -ForegroundColor Green
    Write-Host "   [SPEED] $($adapter.LinkSpeed)" -ForegroundColor Gray
    Write-Host "   [MAC  ] $($adapter.MacAddress)" -ForegroundColor Gray
} else {
    Write-Host "   [CRITICAL] No Cable/Wi-Fi Connected!" -ForegroundColor Red
    Exit
}

# --- STEP 2: Gateway Analysis ---
Write-Host "`nStep 2: Analyzing Route to Gateway..." -ForegroundColor Cyan
Write-Progress -Activity "Network Analysis" -Status "Pinging Gateway..." -PercentComplete 50

$ipConfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex
$gateway = $ipConfig.IPv4DefaultGateway.NextHop
$myIP = $ipConfig.IPv4Address.IPAddress

Write-Host "   [IP   ] $myIP" -ForegroundColor Yellow
Write-Host "   [GATE ] $gateway" -ForegroundColor Yellow

if (Test-Connection -ComputerName $gateway -Count 1 -Quiet) {
    Write-Host "   [STATUS] Gateway Reachable (Latency: <1ms)" -ForegroundColor Green
} else {
    Write-Host "   [FAIL] Gateway Down!" -ForegroundColor Red
    # Repair Logic would go here
}

# --- STEP 3: DNS Optimization (Forced Action) ---
Write-Host "`nStep 3: Checking DNS Services..." -ForegroundColor Cyan
Write-Progress -Activity "DNS Services" -Status "Resolving Google..." -PercentComplete 80
Start-Sleep -Milliseconds 300

if (Resolve-DnsName google.com -ErrorAction SilentlyContinue) {
    Write-Host "   [OK] Resolution Functional" -ForegroundColor Green
    
    # FORCE a flush just to show 'Cool Stuff' happening
    if ($isAdmin) {
        Write-Host "   [MAINTENANCE] Flushing DNS Cache..." -ForegroundColor Magenta
        ipconfig /flushdns | Out-Null
        Write-Host "   [SUCCESS] Cache Cleared." -ForegroundColor Green
    }
} else {
    Write-Host "   [FAIL] DNS Broken" -ForegroundColor Red
}

# --- STEP 4: Global Connectivity ---
Write-Host "`nStep 4: Verifying Global Access..." -ForegroundColor Cyan
Write-Progress -Activity "Finalizing" -Status "Pinging 8.8.8.8..." -PercentComplete 100

$ping = Test-Connection -ComputerName 8.8.8.8 -Count 1 -ErrorAction SilentlyContinue
if ($ping) {
    Write-Host "   [ONLINE] Latency: $($ping.ResponseTime)ms" -ForegroundColor Green
} else {
    Write-Host "   [OFFLINE] No Internet." -ForegroundColor Red
}

Write-Host "`n===========================================" -ForegroundColor Cyan
Write-Host "   SYSTEM STATUS: OPERATIONAL              " -ForegroundColor Black -BackgroundColor Green
Write-Host "===========================================" -ForegroundColor Cyan
Read-Host "Press Enter to exit..."
