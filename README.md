# Interactive Network Scanner for Kali Linux

A user-friendly Bash script designed for Kali Linux that simplifies network discovery and security scanning. It allows users to quickly find live hosts on their local network and perform a variety of Nmap scans on selected targets through an interactive menu system.

## Features

- **Automatic Network Discovery:** The script automatically detects your local network range (e.g., `192.168.1.0/24`).
- **Live Host Detection:** Uses `nmap -sn` to efficiently find all active devices on the network.
- **Interactive Menus:** Provides clear, numbered menus for selecting target devices and scan types, making it easy to use without memorizing Nmap commands.
- **New Device Highlighting:** When you rescan the network, any newly discovered devices are highlighted in green, so you can spot changes instantly.
- **Multiple Scan Options:** Offers a variety of pre-configured Nmap scans, including:
    - Service Version Detection (`-sV`)
    - Aggressive Scan (`-A`)
    - OS Detection (`-O`)
    - TCP SYN (Stealth) Scan (`-sS`)
    - Full Port Scan (`-p-`)
    - UDP Scan (`-sU`)
    - Custom Scan (enter your own flags)
- **Cancel Individual Scans:** You can cancel a running Nmap scan by pressing `Ctrl+C` without terminating the entire script.
- **Persistent & On-Demand Scanning:** The script doesn't automatically rescan the network every time. You can work with the current list of devices and trigger a new scan manually whenever you choose.

## Requirements

- **Kali Linux** (or another Debian-based distro)
- **Nmap:** `sudo apt install nmap`
- **iproute2:** (Usually pre-installed) `sudo apt install iproute2`

## How to Use

1.  **Save the Script:**
    Save the script content as a file named `netscan.sh`.

2.  **Make it Executable:**
    Open a terminal and run the following command to grant execution permissions:
    ```bash
    chmod +x netscan.sh
    ```

3.  **Run with Sudo:**
    For best results and to ensure all Nmap scans work correctly (especially OS detection and SYN scans), run the script with `sudo`:
    ```bash
    sudo ./netscan.sh
    ```

## Usage Flow

1.  The script starts and immediately scans your local network for live hosts.
2.  A numbered list of all discovered IP addresses is displayed.
3.  You can select a target IP from the list or choose the option to "Scan again for new devices."
4.  Once a target is selected, a new menu appears with different Nmap scan types.
5.  Choose a scan. The script will show you the command it's about to run.
6.  The Nmap results are displayed in your terminal.
7.  After the scan, you can press `Enter` to return to the scan menu for the same device or choose "Go Back" to return to the device list.
8.  Press `Ctrl+C` at any menu (but not during a scan) to exit the script gracefully.

---
This project is intended for educational and authorized security testing purposes only.
