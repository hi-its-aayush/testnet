# Connectivity Investigator v1.0
# Author: Aayush Acharya
Clear-Host
Write-Host "--- Starting Network Diagnostic ---" -ForegroundColor Cyan

# 1. Identify Local Adapter Status
$Adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
if ($null -eq $Adapter) {
    Write-Host "[FAIL] No active network adapters found. Check your cable or Wi-Fi switch." -ForegroundColor Red
    return
}
Write-Host "[OK] Using Adapter: $($Adapter.Name) ($($Adapter.InterfaceDescription))" -ForegroundColor Green

# 2. Get Gateway IP
$Gateway = (Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Select-Object -ExpandProperty NextHop -ErrorAction SilentlyContinue)
if ($null -eq $Gateway) {
    Write-Host "[FAIL] No Default Gateway found. You are likely not connected to a router." -ForegroundColor Red
} else {
    Write-Host "[DEBUG] Testing Gateway: $Gateway"
    if (Test-Connection -ComputerName $Gateway -Count 1 -Quiet) {
        Write-Host "[OK] Local Router (Gateway) is reachable." -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Gateway is not responding. Check your router power/connection." -ForegroundColor Red
    }
}

# 3. Test External IP Connectivity (The "Outside World")
if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet) {
    Write-Host "[OK] Internet IP access (8.8.8.8) is working." -ForegroundColor Green
} else {
    Write-Host "[FAIL] No internet access via IP. ISP or WAN link might be down." -ForegroundColor Red
}

# 4. Test DNS Resolution
try {
    $DNS = Resolve-DnsName -Name google.com -ErrorAction Stop
    Write-Host "[OK] DNS Resolution is working (Resolved to $($DNS.IPAddress))." -ForegroundColor Green
} catch {
    Write-Host "[FAIL] DNS Resolution failed. You have a DNS configuration issue." -ForegroundColor Red
}

Write-Host "`n--- Diagnostic Complete ---" -ForegroundColor Cyan
