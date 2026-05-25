#!/bin/zsh

# Ensure root privileges are present for low-level raw socket interactions
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[1;31m[!] Error: Advanced Nmap scanning requires administrative raw socket permissions.\e[0m"
  echo -e "\e[1;33m[*] Please re-execute this script using: sudo boltnmap\e[0m"
  exit 1
fi

clear

# --- Global Tracking Configuration Variables ---
TARGET=""
OUTPUT_DIR=""

# --- ADVANCED TIMING, STABILIZATION & PROGRESS MONITOR ENGINE ---
monitor_nmap_progress() {
    local target_pid=$1
    local scan_title=$2
    local est_secs=$3
    local elapsed=0
    
    # Allow a brief stabilization interval for network sockets to map out cleanly
    sleep 1

    # Keep looping if the specific PID is alive OR an nmap instance is actively processing in the background
    while kill -0 $target_pid 2>/dev/null || pgrep -x "nmap" >/dev/null; do
        sleep 2
        ((elapsed+=2))
        
        # Calculate smooth percentage acceleration transitions mapping to historical metrics
        local display_pct=$(( (elapsed * 95) / est_secs ))
        [[ $display_pct -ge 95 ]] && display_pct=95
        
        printf "\r\e[1;32m    [+] Progress: [%-20s] %d%% | Active: %-15s (%ds / Est: %ds)\e[0m" \
            "$(printf '#%.0s' {1..$((display_pct/5))})" "$display_pct" "$scan_title" "$elapsed" "$est_secs"
    done
    
    # Await clean shell exit cleanup parameters
    wait $target_pid 2>/dev/null
    printf "\r\e[1;32m    [+] Progress: [%-20s] 100%% | Done: %-20s (%ds total)           \n\e[0m" \
        "$(printf '#%.0s' {1..20})" "$scan_title" "$elapsed"
}

# --- SMART NETWORK RANGE PARSER & TARGET CHOOSER ---
check_and_parse_target() {
    if [ -z "$TARGET" ]; then
        echo -e "\n\e[1;31m[!] Configuration Target Scope is currently undefined.\e[0m"
        read "TARGET?[?] Enter target network scope (e.g., 192.168.74.131 or 192.168.74.0/24): "
    fi

    if [ -z "$TARGET" ]; then
        echo -e "\e[1;31m[!] Aborting: Empty target declaration.\e[0m"
        return 1
    fi

    # Detect if user entered a CIDR Subnet Block range (e.g., /24, /16)
    if [[ "$TARGET" == *"/"* ]]; then
        echo -e "\n\e[1;33m[*] CIDR Range detected! Initiating fast host discovery sweep...\e[0m"
        
        # Perform quick ping sweep to map live hosts
        local TMP_DISCOVERY=$(mktemp)
        nmap -sn -n "$TARGET" -oG - | grep "Host:" | awk '{print $2}' > "$TMP_DISCOVERY"
        
        local HOST_COUNT=$(wc -l < "$TMP_DISCOVERY")
        
        if [ "$HOST_COUNT" -eq 0 ]; then
            echo -e "\e[1;31m[!] No live hosts discovered on subnet range: $TARGET\e[0m"
            rm -f "$TMP_DISCOVERY"
            TARGET=""
            return 1
        fi
        
        # Build interactive target choosing list
        echo -e "\e[1;32m[+] Discovered $HOST_COUNT Live Hosts on Subnet:\e[0m"
        local -A host_map
        local index=1
        
        echo "    0) Audit the ENTIRE network range concurrently ($TARGET)"
        while IFS= read -r host_ip; do
            echo "    ${index}) Target Host Node: $host_ip"
            host_map[$index]=$host_ip
            ((index++))
        done < "$TMP_DISCOVERY"
        
        echo -e "\e[1;35m------------------------------------------------------------------\e[0m"
        read "SELECTION?[?] Choose your specific assessment target (0-${#host_map}): "
        
        if [[ "$SELECTION" == "0" ]]; then
            echo -e "\e[1;32m[*] Sticking with global scope range: $TARGET\e[0m"
        elif [ -n "${host_map[$SELECTION]}" ]; then
            TARGET="${host_map[$SELECTION]}"
            echo -e "\e[1;32m[+] Target updated to isolated host: $TARGET\e[0m"
        else
            echo -e "\e[1;31m[!] Invalid selection. Defaulting to entire subnet sweep range.\e[0m"
        fi
        rm -f "$TMP_DISCOVERY"
    fi
    return 0
}

# --- EXECUTIVE ENGINE CALL WRAPPER ---
execute_nmap() {
    local scan_title=$1
    local scan_args=$2
    local baseline_est_seconds=$3
    
    check_and_parse_target || return
    
    # Define clean local directories where you sit
    local SANITIZED_NAME=$(echo "$TARGET" | tr -d '[:space:]' | tr '/' '_')
    OUTPUT_DIR="$(pwd)/nmap_result_${SANITIZED_NAME}"
    mkdir -p "$OUTPUT_DIR"
    
    local LOG_FILE="$OUTPUT_DIR/nmap_${scan_title}_${SANITIZED_NAME}.txt"
    
    # --- TAILORED FIX FOR STUCK UDP SCANS ---
    # Intercept UDP profiles and append strict optimization matrices to stop the 95% hang
    if [[ "$scan_args" == *"-sU"* ]]; then
        scan_args="$scan_args --max-retries 1 --delay 500ms"
    fi
    
    echo -e "\n\e[1;36m------------------------------------------------------------------\e[0m"
    echo -e "\e[1;37m[i] BASE COMMAND PREVIEW:\e[0m"
    echo -e "    \e[1;34mnmap $scan_args -v -oN \"$LOG_FILE\" $TARGET\e[0m"
    echo -e "\e[1;36m------------------------------------------------------------------\e[0m"
    
    echo -e "\e[1;37m[?] Enter any extra custom Nmap options you want to append (or press ENTER):\e[0m"
    read "EXTRA_FLAGS? > "
    
    local CONSOLIDATED_ARGS="$scan_args"
    if [ -n "$EXTRA_FLAGS" ]; then
        CONSOLIDATED_ARGS="$scan_args $EXTRA_FLAGS"
        if [[ "$EXTRA_FLAGS" == *"-T4"* ]]; then
            baseline_est_seconds=$((baseline_est_seconds / 2))
        elif [[ "$EXTRA_FLAGS" == *"-T5"* ]]; then
            baseline_est_seconds=$((baseline_est_seconds / 3))
        fi
    fi

    clear
    echo -e "\e[1;33mFiring Background Packet Engine Thread against: $TARGET...\e[0m"
    echo -e "\e[1;35m------------------------------------------------------------------\e[0m"
    
    # Launch Nmap and explicitly pipe out all background stream operations
    nmap ${=CONSOLIDATED_ARGS} -v -oN "$LOG_FILE" "$TARGET" >/dev/null 2>&1 &
    local nmap_pid=$!
    
    # Engage the structural stabilization tracker loop
    monitor_nmap_progress $nmap_pid "$scan_title" $baseline_est_seconds
    
    echo -e "\n\e[1;35m------------------------------------------------------------------\e[0m"
    echo -e "\e[1;32m[+] Execution Thread Completed.\e[0m"
    echo -e "\e[1;37m[+] Raw Output Captured at: $LOG_FILE\e[0m"
    echo -e "------------------------------------------------------------------"
    read "PAUSE?[*] Press [ENTER] to return back to sub-menu layer..."
}

# --- SUB-MENU LAYERS ---
menu_scanning_techniques() {
    while true; do
        clear
        echo -e "\e[1;36m--- SUB-MENU: CORE PORT DISCOVERY & SCANNING TECHNIQUES ---\e[0m"
        echo "1) Stealth SYN Scan (-sS) [Default Standard]"
        echo "2) Full TCP Connect Scan (-sT)"
        echo "3) UDP Infrastructure Scan (-sU) [Anti-Hang Optimized]"
        echo "4) FIN Packet Stealth Scan (-sF)"
        echo "5) Xmas Frame Profile Scan (-sX)"
        echo "6) NULL Box Packet Scan (-sN)"
        echo "B) Back to Main Framework Root Menu"
        echo "------------------------------------------------------------------"
        read "CHOICE?[?] Select scanning technique option: "
        
        case "$CHOICE" in
            1) execute_nmap "Stealth_SYN" "-sS" 45 ;;
            2) execute_nmap "TCP_Connect" "-sT" 30 ;;
            3) execute_nmap "UDP_Deep" "-sU" 60 ;; 
            4) execute_nmap "FIN_Stealth" "-sF" 50 ;;
            5) execute_nmap "Xmas_Frame" "-sX" 50 ;;
            6) execute_nmap "NULL_Scan" "-sN" 50 ;;
            [Bb]) return ;;
            *) echo -e "\e[1;31m[!] Invalid Input.\e[0m"; sleep 1 ;;
        esac
    done
}

menu_nse_scripts() {
    while true; do
        clear
        echo -e "\e[1;36m--- SUB-MENU: NMAP SCRIPTING ENGINE (NSE) VULN MATRIX ---\e[0m"
        echo "1) Default Core Operational Analysis Scripts (-sC)"
        echo "2) Broad Vulnerability Assessment Engine Discovery (--script vuln)"
        echo "3) Aggressive Malware and Backdoor Subsystem Check (--script malware)"
        echo "4) Information Gathering / Reconnaissance Profiling (--script discovery)"
        echo "B) Back to Main Framework Root Menu"
        echo "------------------------------------------------------------------"
        read "CHOICE?[?] Select NSE automation script option: "
        
        case "$CHOICE" in
            1) execute_nmap "NSE_Default" "-sC" 60 ;;
            2) execute_nmap "NSE_Vuln_Check" "--script vuln" 180 ;;
            3) execute_nmap "NSE_Malware_Audit" "--script malware" 90 ;;
            4) execute_nmap "NSE_Discovery" "--script discovery" 120 ;;
            [Bb]) return ;;
            *) echo -e "\e[1;31m[!] Invalid Input.\e[0m"; sleep 1 ;;
        esac
    done
}

menu_evasion_spoofing() {
    while true; do
        clear
        echo -e "\e[1;36m--- SUB-MENU: FIREWALL EVASION, IDLE SCANNING & SPOOFING ---\e[0m"
        echo "1) Fragment IP Packets into MTU Sizes (-f)"
        echo "2) Inject Invalid TCP/UDP Checksums (--badsum)"
        echo "3) Randomize Target Host Scan Sequence Processing (--randomize-hosts)"
        echo "B) Back to Main Framework Root Menu"
        echo "------------------------------------------------------------------"
        read "CHOICE?[?] Select evasion/spoofing option: "
        
        case "$CHOICE" in
            1) execute_nmap "IP_Fragmentation" "-f" 40 ;;
            2) execute_nmap "Bad_Checksum_Probe" "--badsum" 30 ;;
            3) execute_nmap "Host_Randomization" "--randomize-hosts" 45 ;;
            [Bb]) return ;;
            *) echo -e "\e[1;31m[!] Invalid Input.\e[0m"; sleep 1 ;;
        esac
    done
}

# --- ROOT MENU EXECUTION LOOP ---
if [ -n "$1" ]; then
    TARGET="$1"
fi

while true; do
    clear
    echo -e "\e[1;34m==================================================================\e[0m"
    echo -e "\e[1;32m         BOLTNMAP INTELLIGENT MASTER NMAP ENGINE CONTROL CONSOLE  \e[0m"
    echo -e "\e[1;34m==================================================================\e[0m"
    
    if [ -n "$TARGET" ]; then
        echo -e " Current Target Scope : \e[1;32m$TARGET\e[0m"
        echo -e " Output Local Directory: \e[1;37m./nmap_result_${TARGET//./_}/\e[0m"
    else
        echo -e " Current Target Scope : \e[1;31m[NOT CONFIGURED - WILL PROMPT UPON EXECUTION]\e[0m"
    fi
    echo "--------------------------------------------------"
    echo "1) Update Target Host Configuration Address / Range"
    echo "2) Core Scanning Techniques Menu (SYN, UDP, TCP Connect, Xmas, NULL)"
    echo "3) Integrated Fingerprinting Service Audit (-sV -O -A --osscan-guess)"
    echo "4) Nmap Scripting Engine (NSE) Automation Matrix Menu"
    echo "5) Firewall Evasion, IP Fragmentation & Packet Bypass Configurations"
    echo "E) Terminate Terminal Interface Operations"
    echo "=================================================================="
    read "MAIN_CHOICE?[?] Select structural category index: "
    
    case "$MAIN_CHOICE" in
        1) read "TARGET?[?] Define your evaluation scope domain / IP address: " 
           OUTPUT_DIR="" ;;
        2) menu_scanning_techniques ;;
        3) execute_nmap "Integrated_Fingerprinting" "-sV -O -A --osscan-guess" 90 ;;
        4) menu_nse_scripts ;;
        5) menu_evasion_spoofing ;;
        [Ee]) 
            echo -e "\n\e[1;33m[*] Shutting down control interfaces. Workspace safely detached.\e[0m\n"
            exit 0 ;;
        *) 
            echo -e "\e[1;31m[!] Unrecognized command instruction.\e[0m"
            sleep 1 ;;
    esac
done
