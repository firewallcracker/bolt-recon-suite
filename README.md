# ⚡ Bolt Recon Suite

A modular, high-velocity automated offensive security reconnaissance framework and network auditing suite. Designed to streamline target infrastructure mapping, asset discovery, and vulnerability profiling during penetration testing assessments and bug bounty hunting.

---

## 📁 Included Automation Tools

### 1. BoltScan Advance (`boltscan_advance.sh`)
An advanced web infrastructure reconnaissance and automated perimeter handling pipeline.
* **Core Capabilities:** * High-speed subdomain enumeration.
  * Active HTTP/HTTPS live web asset probing (filtering out HTTP 404 noise logs).
  * Automated JSON response parsing to pull clean target URLs.
  * Structural technology-stack mapping using custom queries.
  * Core parameter checking for critical exposed files (`.env`, `config.json`, `robots.txt`, `.git/HEAD`).
* **Underlying Engine:** `subfinder`, `httpx`, `jq`, `ffuf`.

### 2. BoltNmap (`boltnmap.sh`)
An automated network scanner and service enumerator utility designed to rapidly map host perimeters, running services, and operational version fingerprints cleanly without screen clutter.
* **Underlying Engine:** `nmap`.

---

## 🛠️ Installation & Dependencies Setup

Ensure you have all the required active offensive security binaries installed on your local Kali Linux system before deploying the suite:

```bash
sudo apt update && sudo apt install subfinder httpx jq ffuf nmap -y

```

---

## 🚀 Execution Guide

Clone this repository or navigate to your script directory and grant explicit execution permissions to the framework core:

```bash
# 1. Grant system execution rights
chmod +x boltscan_advance.sh boltnmap.sh

# 2. Launch the Web Recon Engine Pipeline
./boltscan_advance.sh target.com

```

### 🎯 Sample Output Architecture

Upon initialization, **BoltScan Advance** will automatically construct a dedicated, isolated tracking folder mapped with the target name and a real-time timestamp layout (`boltscan_target.com_YYYY-MM-DD_HHMMSS/`) to store your structured recon artifacts:

* `subdomains.txt` - Complete subdomain map.
* `live_urls.txt` - Active live HTTP/HTTPS root nodes.
* `tech_stack_mapping.txt` - Fingerprinted system components.
* `fuzz_results.json` - Detected sensitive perimeter asset configurations.

---

*Disclaimer: This toolkit is built strictly for authorized security auditing, professional infrastructure penetration testing, and educational bug bounty research tracking. Always ensure explicit permission from target asset holders before deployment.*
