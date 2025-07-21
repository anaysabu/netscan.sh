#!/bin/bash

#==============================================================================
#
#          FILE: netscan.sh
#
#         USAGE: ./netscan.sh
#
#   DESCRIPTION: An interactive script to discover live hosts on the local
#                network and perform various Nmap scans on a selected target.
#
#       OPTIONS: ---
#  REQUIREMENTS: nmap, iproute2
#          BUGS: ---
#         NOTES: Run with sudo for best results, especially for OS detection
#                and SYN scans.
#        AUTHOR: ANAY SABU 
#                github.com/anaysabu
#
#==============================================================================

# --- Colors for better readability ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Function to check for required tools ---
check_dependencies() {
    if ! command -v nmap &> /dev/null; then
        echo -e "${RED}Error: nmap is not installed. Please install it with 'sudo apt update && sudo apt install nmap'${NC}"
        exit 1
    fi
    if ! command -v ip &> /dev/null; then
        echo -e "${RED}Error: iproute2 is not installed. This is highly unusual. Please install it.${NC}"
        exit 1
    fi
}

# --- Function to find the local network range ---
find_network_range() {
    echo -e "${CYAN}[*] Discovering local network range...${NC}" >&2
    local network_range=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -n 1)

    if [ -z "$network_range" ]; then
        echo -e "${RED}Error: Could not determine the local network range. Is your network interface up?${NC}" >&2
        exit 1
    fi
    echo -e "${GREEN}[+] Network range found: ${YELLOW}$network_range${NC}" >&2
    echo "$network_range"
}

# --- Function to discover live hosts on the network ---
discover_hosts() {
    local network_range=$1
    echo -e "\n${CYAN}[*] Scanning for live devices on ${YELLOW}$network_range${NC}..."
    echo -e "${CYAN}[*] This may take a moment. Using 'nmap -sn' (Ping Scan)...${NC}"
    
    nmap -sn "$network_range" -oG - | awk '/Up$/{print $2}' > /tmp/live_hosts.txt
    mapfile -t live_hosts < /tmp/live_hosts.txt
    rm /tmp/live_hosts.txt

    if [ ${#live_hosts[@]} -eq 0 ]; then
        echo -e "\n${RED}No devices found on the network. Try running the script with sudo.${NC}"
    else
        echo -e "\n${GREEN}[+] Discovery complete! Found ${YELLOW}${#live_hosts[@]}${GREEN} active device(s).${NC}"
    fi
}

# --- Helper function to check if an element is in an array ---
# Usage: containsElement "search_string" "${array[@]}"
containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

# --- Function to let the user select a target host ---
select_target() {
    echo -e "\n${BLUE}--- Please select a target device ---${NC}"
    
    local menu_options=()
    local new_device_found=false
    # Build the menu options, highlighting new devices
    for host in "${live_hosts[@]}"; do
        # A device is new if it's not in the previous list AND the previous list was not empty (i.e. not the first scan)
        if ! containsElement "$host" "${previous_hosts[@]}" && [ ${#previous_hosts[@]} -gt 0 ]; then
            menu_options+=("$(echo -e "${GREEN}[NEW]${NC} $host")")
            new_device_found=true
        else
            menu_options+=("$host")
        fi
    done

    if [ "$new_device_found" = true ]; then
        echo -e "${GREEN}-> New devices are highlighted!${NC}"
    fi

    # Add the rescan option at the end
    menu_options+=("Scan again for new devices")

    # Manually print the menu because 'select' doesn't handle pre-formatted strings well
    while true; do
        local i=1
        for item in "${menu_options[@]}"; do
            echo -e "  $i) $item"
            ((i++))
        done

        read -p "Please enter your choice [1-${#menu_options[@]}]: " choice_num

        # Validate if the input is a number and within range
        if ! [[ "$choice_num" =~ ^[0-9]+$ ]] || [ "$choice_num" -lt 1 ] || [ "$choice_num" -gt ${#menu_options[@]} ]; then
            echo -e "${RED}Invalid selection. Please try again.${NC}"
            continue
        fi

        # Get the selected item from the array (index is choice-1)
        local selected_item="${menu_options[$((choice_num-1))]}"

        if [[ "$selected_item" == "Scan again for new devices" ]]; then
            target_ip="RESCAN"
            break
        else
            # It's a host. Strip any color codes and prefixes to get the raw IP.
            local raw_item=$(echo "$selected_item" | sed -r "s/\x1B\[[0-9;]*[mK]//g") # Removes ANSI color codes
            local clean_ip=$(echo "$raw_item" | awk '{print $NF}') # Gets the last field, which is the IP
            
            echo -e "${GREEN}You have selected: ${YELLOW}$clean_ip${NC}"
            target_ip="$clean_ip"
            break
        fi
    done
}


# --- Function to display the scan menu and execute the chosen scan ---
scan_menu() {
    local target=$1
    
    while true; do
        clear
        echo -e "\n${BLUE}--- Select a scan for ${YELLOW}$target${BLUE} ---${NC}"
        echo -e "1) ${CYAN}Service Version Scan (-sV)${NC}  | Finds service versions. | ${YELLOW}Time: Medium${NC}"
        echo -e "2) ${CYAN}Aggressive Scan (-A)${NC}       | OS/Version detection, scripts, traceroute. | ${YELLOW}Time: Slow${NC}"
        echo -e "3) ${CYAN}OS Detection (-O)${NC}          | Tries to identify the OS. (sudo) | ${YELLOW}Time: Medium${NC}"
        echo -e "4) ${CYAN}Stealth Scan (-sS)${NC}         | Fast, quiet port scan. (sudo) | ${GREEN}Time: Fast${NC}"
        echo -e "5) ${CYAN}Full Port Scan (-p-)${NC}      | Scans all 65535 TCP ports. | ${RED}Time: Very Slow${NC}"
        echo -e "6) ${CYAN}UDP Scan (-sU)${NC}             | Scans for open UDP ports. | ${RED}Time: Very Slow${NC}"
        echo -e "7) ${CYAN}Custom Scan${NC}               | Enter your own Nmap flags."
        echo -e "8) ${YELLOW}Go Back${NC}                   | Return to the device list."
        
        read -p "Enter your choice [1-8]: " choice

        local nmap_command=""
        
        case $choice in
            1) nmap_command="sudo nmap -sV $target";;
            2) nmap_command="sudo nmap -A $target";;
            3) nmap_command="sudo nmap -O $target";;
            4) nmap_command="sudo nmap -sS $target";;
            5) nmap_command="sudo nmap -p- $target";;
            6) nmap_command="sudo nmap -sU $target";;
            7) 
                read -p "Enter custom Nmap flags (e.g., -sC -T4): " custom_flags
                nmap_command="sudo nmap $custom_flags $target"
                ;;
            8) 
                echo -e "${YELLOW}Returning to device list...${NC}"
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                read -p "Press [Enter] to continue..."
                continue
                ;;
        esac

        echo -e "\n${CYAN}======================================================================${NC}"
        echo -e "${CYAN}Executing command: ${YELLOW}${nmap_command}${NC}"
        echo -e "${RED}Press Ctrl+C to cancel THIS scan and return to the menu.${NC}"
        echo -e "${CYAN}======================================================================${NC}\n"
        
        trap '' INT

        eval $nmap_command
        local exit_code=$?

        trap trap_ctrl_c INT

        if [ $exit_code -eq 0 ]; then
            echo -e "\n${GREEN}[+] Scan complete.${NC}"
        else
            echo -e "\n${YELLOW}[!] Scan cancelled or failed (Nmap exit code: $exit_code).${NC}"
        fi
        
        read -p "Press [Enter] to return to the scan menu..."
    done
}

# --- Main script logic ---
main() {
    clear
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}  Kali Linux Interactive Nmap Scanner  ${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo -e "Press ${YELLOW}Ctrl+C${NC} to exit at any time (when not in a scan)."

    check_dependencies
    
    # Declare arrays to hold host IPs globally within the script's scope
    declare -a live_hosts=()
    declare -a previous_hosts=()

    while true; do
        # Before scanning, store the current list of hosts.
        previous_hosts=("${live_hosts[@]}")
        
        local network_range=$(find_network_range)
        discover_hosts "$network_range"

        while true; do
            declare target_ip
            select_target

            if [[ "$target_ip" == "RESCAN" ]]; then
                echo -e "${YELLOW}Rescanning network...${NC}"
                break
            fi
            
            scan_menu "$target_ip"
            
            clear
        done
    done
}

# --- Main trap for Ctrl+C to exit the script gracefully ---
trap_ctrl_c() {
    echo -e "\n\n${YELLOW}Ctrl+C detected. Exiting gracefully.${NC}"
    [ -f /tmp/live_hosts.txt ] && rm /tmp/live_hosts.txt
    exit 0
}

trap trap_ctrl_c INT

# --- Start the script ---
main
