<#
.SYNOPSIS
    Network Connectivity Investigator (NCI) - Enterprise Edition
.DESCRIPTION
    Performs a layered diagnostic of the network stack (L1-L7).
    Identifies Physical, Data Link, Network, and Application layer failures.
.AUTHOR
    Aayush Acharya
#>

[CmdletBinding()]
param()

# --- Setup UI ---
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
Clear-Host

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Color = switch ($Level) {
        "INFO"     { "Cyan" }
        "OK"       { "Green" }
        "WARN"     { "Yellow" }
        "FAIL"     { "Red" }
        "CRITICAL" { "Magenta" }
    }
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] [$Level] $Message" -ForegroundColor $Color
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   NETWORK CONNECTIVITY INVESTIGATOR v2.0" -ForegroundColor White
Write-Host "   Enterprise Diagnostic Tool" -ForegroundColor Gray
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# --- PHASE 1: L1/L2 ADAPTER CHECKS ---
Write-Host "PHASE 1: Hardware & Link Layer" -ForegroundColor Gray

try {
    # Get physical adapters that are actually UP, excluding virtual clutter if possible
    $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Virtual -eq $false }
    
    # Fallback to any Up adapter if no physical ones found (e.g., VM environment)
    if (-not $Adapters) { $Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } }

    $ActiveAdapter = $Adapters | Select-Object -First 1

    if (-not $ActiveAdapter) {
        Write-Log "No active network adapters found. Check physical cabling/switch." "CRITICAL"
        return
    }

    Write-Log "Selected Adapter: $($ActiveAdapter.Name)" "INFO"
    Write-Log "   > Interface:  $($ActiveAdapter.InterfaceDescription)" "INFO"
    Write-Log "   > Link Speed: $($ActiveAdapter.LinkSpeed)" "INFO"
    Write-Log "   > MAC Address: $($ActiveAdapter.MacAddress)" "INFO"
} catch {
    Write-Log "Failed to enumerate network adapters: $_" "FAIL"
    return
}

# --- PHASE 2: L3 NETWORK CONFIGURATION ---
Write-Host "`nPHASE 2: Network Layer (IP Configuration)" -ForegroundColor Gray

$IPConfig = Get-NetIPAddress -InterfaceIndex $ActiveAdapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue

if ($IPConfig) {
    foreach ($IP in $IPConfig) {
        if ($IP.IPAddress -match "^169\.254") {
            Write-Log "APIPA Address Detected ($($IP.IPAddress))" "CRITICAL"
            Write-Log "   > DIAGNOSIS: DHCP Failure. Computer cannot contact DHCP server." "WARN"
            Write-Log "   > ACTION: Check DHCP Scope, Relay Agent, or Restart Router." "WARN"
        } else {
            Write-Log "Valid Local IP: $($IP.IPAddress) (Prefix: /$($IP.PrefixLength))" "OK"
        }
    }
} else {
    Write-Log "No IPv4 Address assigned to adapter." "FAIL"
}

# --- PHASE 3: GATEWAY REACHABILITY ---
Write-Host "`nPHASE 3: Routing & Gateway" -ForegroundColor Gray

$GatewayRoute = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -AddressFamily IPv4 -InterfaceIndex $ActiveAdapter.ifIndex -ErrorAction SilentlyContinue | Select-Object -First 1

if ($GatewayRoute) {
    $GatewayIP = $GatewayRoute.NextHop
    Write-Log "Default Gateway identified: $GatewayIP" "INFO"
    
    if (Test-Connection -ComputerName $GatewayIP -Count 1 -Quiet) {
        Write-Log "Gateway is reachable (Local LAN is healthy)." "OK"
    } else {
        Write-Log "Gateway ($GatewayIP) is UNREACHABLE." "FAIL"
        Write-Log "   > ACTION: Check Router power, VLAN tagging, or Gateway Firewall." "WARN"
    }
} else {
    Write-Log "No Default Gateway found. Cannot route to internet." "FAIL"
}

# --- PHASE 4: WAN CONNECTIVITY ---
Write-Host "`nPHASE 4: WAN Connectivity (Ping Test)" -ForegroundColor Gray

$PingTarget = "8.8.8.8"
if (Test-Connection -ComputerName $PingTarget -Count 1 -Quiet) {
    Write-Log "Internet Reachability (via $PingTarget): SUCCESS" "OK"
} else {
    Write-Log "Internet Reachability (via $PingTarget): FAILED" "FAIL"
    Write-Log "   > DIAGNOSIS: ISP Link Down or Route Filtering active." "WARN"
}

# --- PHASE 5: DNS RESOLUTION ---
Write-Host "`nPHASE 5: Application Layer (DNS)" -ForegroundColor Gray

$DNSTarget = "google.com"
try {
    $DNSResult = Resolve-DnsName -Name $DNSTarget -Type A -ErrorAction Stop | Select-Object -First 1
    Write-Log "DNS Resolution ($DNSTarget): SUCCESS -> $($DNSResult.IPAddress)" "OK"
} catch {
    Write-Log "DNS Resolution Failed." "FAIL"
    Write-Log "   > ACTION: Check DNS Server settings (Current: $((Get-DnsClientServerAddress -InterfaceIndex $ActiveAdapter.ifIndex).ServerAddresses))" "WARN"
    Write-Log "   > RECOMMENDATION: Try 'ipconfig /flushdns' or set DNS to 8.8.8.8." "WARN"
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "   DIAGNOSTIC COMPLETE" -ForegroundColor White
Write-Host "==========================================" -ForegroundColor Cyan
