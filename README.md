# 🛠️ AutoNetFix: PowerShell Network Troubleshooter

![Platform](https://img.shields.io/badge/Platform-Windows-blue) ![Language](https://img.shields.io/badge/Language-PowerShell-yellow) ![License](https://img.shields.io/badge/License-MIT-green)

A lightweight, automated CLI tool designed to detect, diagnose, and resolve common network connectivity issues on Windows machines without user intervention.

> **Why I built this:** As an IT professional, I noticed 80% of Level 1 connectivity tickets were resolved by the same sequence of commands (IP renewal, DNS flushes, Adapter resets). I scripted this logic to automate the "First Response" process.

## 🚀 One-Line Execution
Run this command in PowerShell to instantly diagnose and fix your network (requires internet to fetch, or download locally):

```powershell
iwr raw.githubusercontent.com/hi-its-aayush/testnet/main/NetFix.ps1 -usebasicparsing | iex
