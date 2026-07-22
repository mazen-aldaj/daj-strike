#!/data/data/com.termux/files/usr/bin/bash

# تثبيت الحزم الأساسية بصمت (تأكد من وجودها)
pkg install traceroute nmap dnsutils curl -y >/dev/null 2>&1

# تعريف الألوان
CYAN='\e[1;36m'
MAGENTA='\e[1;35m'
GREEN='\e[1;32m'
RED='\e[1;31m'
YELLOW='\e[1;33m'
WHITE='\e[1;37m'
GRAY='\e[1;30m'
NC='\e[0m'

# تعريف متغيرات عامة
TIMEOUT_SCAN=1 # ثانية واحدة لعمليات الفحص لتجنب التجميد

# ---------------------------------------------------------------------------
# وظائف الواجهة البصرية (UI/UX)
# ---------------------------------------------------------------------------

show_banner() {
    clear
    echo -e "${CYAN}┌────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${MAGENTA}⚡ ${WHITE}N E X U S   N E T W O R K   S U I T E  v11.0 ${MAGENTA}⚡${NC}  ${CYAN}│${NC}"
    echo -e "${CYAN}├────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}       ${GREEN}🧬 CYBER ARCHITECT: MAZEN Al-Daj 🧬${NC}           ${CYAN}│${NC}"
    echo -e "${CYAN}└────────────────────────────────────────────────────┘${NC}"
    echo ""
}

animate_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr="/-\\"
    while [ "$(ps -p $pid -o pid=)" ]; do
        local temp=${spinstr#?}
        printf "\r${YELLOW}[*] %c ${NC}" "$spinstr"
        spinstr=$temp${spinstr%${temp#?}}
        sleep $delay
    done
    printf "\r${GREEN}[+] ${NC}"
}

# ---------------------------------------------------------------------------
# وظائف الفحص الأساسية (من النسخة السابقة مع تحسينات)
# ---------------------------------------------------------------------------

get_subnet() {
    gateway_ip=""
    subnet="192.168.1"
    # محاولة الحصول على الـ Gateway IP باستخدام traceroute مع timeout
    gateway_ip=$(traceroute -4 -m 1 -w ${TIMEOUT_SCAN} 8.8.8.8 2>/dev/null | awk '/1/{print $2}' | grep -E '^[0-9.]+')
    if [ ! -z "$gateway_ip" ]; then
        subnet=$(echo "$gateway_ip" | cut -d. -f1-3)
    fi
}

scan_network() {
    show_banner
    echo -e "${MAGENTA}[*] Booting network reconnaissance core...${NC}"
    get_subnet & animate_spinner $!
    echo -e "${GREEN}[+] Active Target Subnet: ${subnet}.0/24${NC}"
    echo -e "${YELLOW}[!] Scanning infrastructure ports [80/443]...${NC}"
    echo -e "${GRAY}─[ Nodes Analysis ]───────────────────────────────────${NC}"
    
    local PIDS=()
    for i in {1..254}; do
        ip="${subnet}.${i}"
        (
            if nc -w ${TIMEOUT_SCAN} -z $ip 80 >/dev/null 2>&1 || nc -w ${TIMEOUT_SCAN} -z $ip 443 >/dev/null 2>&1; then
                if [ "$ip" == "$gateway_ip" ]; then
                    echo -e "${GREEN}[ONLINE]  ${CYAN}➔  ${WHITE}Device Located: ${RED}$ip [CORE ROUTER]${NC}"
                else
                    echo -e "${GREEN}[ONLINE]  ${CYAN}➔  ${WHITE}Device Located: ${MAGENTA}$ip [ACCESS POINT / AP]${NC}"
                fi
            fi
        ) & PIDS+=($!)
        # التحكم بمعدل العمليات في الثانية لمنع استثارة الأندرويد
        if (( i % 10 == 0 )); then
            for pid in "${PIDS[@]}"; do wait $pid; done
            PIDS=()
        fi
    done
    for pid in "${PIDS[@]}"; do wait $pid; done # انتظار العمليات المتبقية

    echo -e "${GRAY}──────────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}[+] Reconnaissance complete.${NC}\n"
    read -p "Press [Enter] to return to menu..."
}

scan_all_devices() {
    show_banner
    echo -e "${MAGENTA}[*] Initiating Advanced System Identity Resolution...${NC}"
    get_subnet & animate_spinner $!
    echo -e "${GREEN}[+] Active Target Subnet: ${subnet}.0/24${NC}"
    echo -e "${YELLOW}[!] Extracting node strings (Safe Mode)...${NC}"
    echo -e "${GRAY}─[ Connected Clients & Verified Names ]───────────────${NC}"
    
    local PIDS=()
    for i in {1..254}; do
        ip="${subnet}.${i}"
        (
            if ping -c 1 -W ${TIMEOUT_SCAN} $ip >/dev/null 2>&1; then
                hostname=""
                # محاولة الحصول على اسم المضيف باستخدام nmap ثم nslookup مع timeout
                hostname=$(nmap --dns-servers $gateway_ip -sL $ip -T4 --host-timeout ${TIMEOUT_SCAN}s 2>/dev/null | awk '/Nmap scan report for/{print $5}')
                if [[ "$hostname" == "$ip" || -z "$hostname" ]]; then
                    hostname=$(nslookup -timeout=${TIMEOUT_SCAN} $ip $gateway_ip 2>/dev/null | awk -F'= ' '/name =/{print $2}' | sed 's/\.$//')
                fi
                
                if [ ! -z "$hostname" ]; then
                    hostname=$(echo "$hostname" | sed 's/\.netis\.cc//g')
                fi
                
                if [ -z "$hostname" ]; then
                    if [ "$ip" == "$gateway_ip" ]; then
                        hostname="Main_Gateway_Router"
                    elif nc -w ${TIMEOUT_SCAN} -z $ip 80 >/dev/null 2>&1; then
                        hostname="Netis_Access_Point"
                    else
                        hostname="Active_Client_Node"
                    fi
                fi
                echo -e "${CYAN}[HOST-ALIVE] ${CYAN}➔ ${WHITE}IP: ${YELLOW}$ip ${CYAN}| ${WHITE}Identity: ${GREEN}$hostname${NC}"
            fi
        ) & PIDS+=($!)
        if (( i % 10 == 0 )); then
            for pid in "${PIDS[@]}"; do wait $pid; done
            PIDS=()
        fi
    done
    for pid in "${PIDS[@]}"; do wait $pid; done

    echo -e "${GRAY}──────────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}[+] Deep identity resolution complete.${NC}\n"
    read -p "Press [Enter] to return to menu..."
}

monitor_ping() {
    show_banner
    echo -e "${MAGENTA}[*] Intercepting data packets to Google Backbone (8.8.8.8)...${NC}"
    echo -e "${RED}[!] Terminate process using [CTRL + C]${NC}"
    echo -e "${GRAY}─[ Live Ping Stream ]─────────────────────────────────${NC}"
    ping -c 15 -W ${TIMEOUT_SCAN} 8.8.8.8 | while read pong; do
        if [[ $pong == *"time="* ]]; then
            time_val=$(echo $pong | grep -o 'time=[0-9.]*' | cut -d= -f2)
            echo -e "${GREEN}[PACKET-IN] ${CYAN}➔ ${WHITE}Response Time: ${YELLOW}${time_val} ms${NC}"
        else
            echo -e "${GRAY}$pong${NC}"
        fi
    done
    echo -e "${GRAY}──────────────────────────────────────────────────────${NC}\n"
    read -p "Press [Enter] to return to menu..."
}

# ---------------------------------------------------------------------------
# ميزات الفحص الميدانية الجديدة
# ---------------------------------------------------------------------------

port_sniper() {
    show_banner
    echo -e "${MAGENTA}[*] Initializing Port Sniper Module...${NC}"
    echo -ne "${YELLOW}Enter Target IP Address: ${NC}"
    read target_ip

    if [[ ! "$target_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${RED}[!] Invalid IP Address format.${NC}"
        sleep 1
        return
    fi

    echo -e "${YELLOW}[!] Scanning common security ports on ${target_ip}...${NC}"
    echo -e "${GRAY}─[ Port Scan Results ]────────────────────────────────${NC}"

    local common_ports="21 22 23 25 53 80 110 135 139 143 443 445 3389 8080"
    local PIDS=()
    for port in $common_ports; do
        (
            if nc -w ${TIMEOUT_SCAN} -z $target_ip $port >/dev/null 2>&1; then
                echo -e "${GREEN}[OPEN]    ${CYAN}➔  ${WHITE}Port ${YELLOW}$port ${CYAN}is open.${NC}"
            else
                echo -e "${GRAY}[CLOSED]  ${CYAN}➔  ${WHITE}Port ${YELLOW}$port ${CYAN}is closed or filtered.${NC}"
            fi
        ) & PIDS+=($!)
        # التحكم في عدد العمليات المتزامنة
        if (( ${#PIDS[@]} % 5 == 0 )); then
            for pid in "${PIDS[@]}"; do wait $pid; done
            PIDS=()
        fi
    done
    for pid in "${PIDS[@]}"; do wait $pid; done

    echo -e "${GRAY}──────────────────────────────────────────────────────${NC}\n"
    echo -e "${GREEN}[+] Port Sniper scan complete.${NC}\n"
    read -p "Press [Enter] to return to menu..."
}

isp_public_ip_recon() {
    show_banner
    echo -e "${MAGENTA}[*] Initiating ISP & Public IP Reconnaissance Module...${NC}"
    echo -e "${YELLOW}[!] Fetching Public IP and ISP details...${NC}"
    echo -e "${GRAY}─[ Reconnaissance Results ]───────────────────────────${NC}"

    public_ip=""
    isp_name=""
    country_name=""

    # استخدام خدمة ipinfo.io للحصول على معلومات الـ IP العام
    # استخدام timeout لضمان عدم التجميد
    response=$(curl -s --max-time ${TIMEOUT_SCAN} https://ipinfo.io/json)
    if [ $? -eq 0 ] && [ ! -z "$response" ]; then
        public_ip=$(echo "$response" | grep -o '"ip": "[0-9.]*"' | cut -d\" -f4)
        isp_name=$(echo "$response" | grep -o '"org": ".*"' | cut -d\" -f4)
        country_name=$(echo "$response" | grep -o '"country": ".*"' | cut -d\" -f4)
    fi

    if [ ! -z "$public_ip" ]; then
        echo -e "${GREEN}[+] Public IP: ${YELLOW}$public_ip${NC}"
    else
        echo -e "${RED}[!] Could not retrieve Public IP.${NC}"
    fi

    if [ ! -z "$isp_name" ]; then
        echo -e "${GREEN}[+] ISP Name: ${YELLOW}$isp_name${NC}"
    else
        echo -e "${RED}[!] Could not retrieve ISP Name.${NC}"
    fi

    if [ ! -z "$country_name" ]; then
        echo -e "${GREEN}[+] Country: ${YELLOW}$country_name${NC}"
    else
        echo -e "${RED}[!] Could not retrieve Country.${NC}"
    fi

    echo -e "${GRAY}──────────────────────────────────────────────────────${NC}\n"
    echo -e "${GREEN}[+] ISP & Public IP Reconnaissance complete.${NC}\n"
    read -p "Press [Enter] to return to menu..."
}

dns_performance_auditor() {
    show_banner
    echo -e "${MAGENTA}[*] Initializing DNS Performance Auditor Module...${NC}"
    echo -e "${YELLOW}[!] Testing global DNS server response times...${NC}"
    echo -e "${GRAY}─[ DNS Performance Results ]──────────────────────────${NC}"

    declare -A dns_servers
    dns_servers["Google DNS"]="8.8.8.8"
    dns_servers["Cloudflare DNS"]="1.1.1.1"
    dns_servers["Quad9 DNS"]="9.9.9.9"

    local PIDS=()
    local results=()

    for name in "${!dns_servers[@]}"; do
        ip=${dns_servers[$name]}
        (
            # استخدام ping لقياس زمن الاستجابة مع timeout
            avg_time=$(ping -c 3 -W ${TIMEOUT_SCAN} $ip 2>/dev/null | grep 'avg' | awk -F'/' '{print $5}')
            if [ ! -z "$avg_time" ]; then
                results+=("$name:$avg_time")
            else
                results+=("$name:N/A")
            fi
        ) & PIDS+=($!)
    done
    for pid in "${PIDS[@]}"; do wait $pid; done

    # فرز النتائج وعرضها
    IFS=$'
' sorted_results=($(sort -t':' -k2,2n <<<"${results[*]}"))
    unset IFS

    for result in "${sorted_results[@]}"; do
        name=$(echo "$result" | cut -d':' -f1)
        time=$(echo "$result" | cut -d':' -f2)
        if [ "$time" == "N/A" ]; then
            echo -e "${RED}[FAIL]    ${CYAN}➔  ${WHITE}$name: ${RED}No response (Timeout)${NC}"
        else
            echo -e "${GREEN}[SUCCESS] ${CYAN}➔  ${WHITE}$name: ${YELLOW}${time} ms${NC}"
        fi
    done

    echo -e "${GRAY}──────────────────────────────────────────────────────${NC}\n"
    echo -e "${GREEN}[+] DNS Performance Audit complete.${NC}\n"
    read -p "Press [Enter] to return to menu..."
}

# ---------------------------------------------------------------------------
# القائمة الرئيسية
# ---------------------------------------------------------------------------

while true; do
    show_banner
    echo -e "${WHITE}Select System Module:${NC}"
    echo -e "  ${CYAN}1) Map Network Architecture${NC}   ${GRAY}(Find Routers/APs)${NC}"
    echo -e "  ${CYAN}2) Discover All Connected Hosts${NC} ${GRAY}(Pull Clean Names)${NC}"
    echo -e "  ${CYAN}3) Monitor Signal Stability${NC}     ${GRAY}(Live Ping Stream)${NC}"
    echo -e "  ${CYAN}4) Port Sniper${NC}                ${GRAY}(Scan Common Ports)${NC}"
    echo -e "  ${CYAN}5) ISP & Public IP Recon${NC}      ${GRAY}(Get Public IP & ISP)${NC}"
    echo -e "  ${CYAN}6) DNS Performance Auditor${NC}    ${GRAY}(Compare DNS Speeds)${NC}"
    echo -e "  ${RED}0) Disconnect Suite${NC}"
    echo ""
    echo -ne "${MAGENTA}MAZEN-ALDAJ${WHITE}@${CYAN}TERMINAL:~$ ${NC}"
    read choice

    case $choice in
        1) scan_network ;;
        2) scan_all_devices ;;
        3) monitor_ping ;;
        4) port_sniper ;;
        5) isp_public_ip_recon ;;
        6) dns_performance_auditor ;;
        0) echo -e "${RED}[-] Shutting down system modules. Goodbye.${NC}" ; exit 0 ;;
        *) echo -e "${RED}[!] Terminal Input Refused! Try again.${NC}" ; sleep 1 ;;
    esac
done
