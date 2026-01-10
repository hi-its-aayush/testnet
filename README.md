# 🌐 Network Connectivity Investigator
![Status](https://img.shields.io/badge/Status-Active-success) ![Platform](https://img.shields.io/badge/Platform-Windows%20PowerShell-blue)

**A diagnostic engine for rapid network troubleshooting.**

This tool follows the **OSI Layer model** to isolate network failures by testing the local adapter, default gateway, external IP connectivity, and DNS resolution. It specifically detects **APIPA (169.254.x.x)** addresses, identifying DHCP failures immediately.

## 🚀 Quick Run (One-Liner)
*Run this diagnostic directly in your terminal. No download required.*

```powershell
irm https://raw.githubusercontent.com/hi-its-aayush/testnet/main/test1.ps1 | iex
