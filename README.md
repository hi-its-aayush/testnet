🌐 Network Connectivity Investigator
A diagnostic engine for rapid network troubleshooting.

This tool follows the OSI model to isolate network failures by testing the local adapter, the default gateway, external IP connectivity, and DNS resolution. It specifically detects APIPA (169.254.x.x) addresses, identifying DHCP failures immediately.

🚀 Quick Run (PowerShell One-Liner)
You can run this diagnostic directly in your terminal without manual downloads. Open PowerShell and paste the following:

PowerShell

irm https://raw.githubusercontent.com/hi-its-aayush/testnet/main/test1.ps1 | iex
Note: irm (Invoke-RestMethod) fetches the code, and iex (Invoke-Expression) executes it in your current session.

🛠 Features
Adapter Health: Verifies if local network hardware is "Up".

APIPA Detection: Identifies 169.254.x.x addresses caused by DHCP exhaustion or failure.

Gateway Check: Pings the local router/gateway to confirm local link integrity.

WAN Validation: Tests connectivity to 8.8.8.8 to bypass potential DNS issues.

DNS Resolution: Confirms if name-to-IP resolution is functioning correctly.

📂 Project Structure
test1.ps1: The primary PowerShell diagnostic script.

README.md: Project documentation and usage instructions.

👤 Author
Aayush Systems Engineering Student | Aspiring Systems Administrator
\
Interview Talk Track: You can tell Rohit at Akkodis: "I've built a diagnostic toolkit on my GitHub. I actually use a one-liner to pull it down to any machine for immediate troubleshooting.
