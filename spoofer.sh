#!/bin/bash

# Check root
if [ "$EUID" -ne 0 ]; then
  echo "You need to run this script as root for changing MAC address."
  exit 1
fi

white="\033[1;37m"
error="\033[0;31m"     
working="\033[0;32m"     
alert="\033[1;33m"
NC="\033[0m"  
bold='\033[1m'
dim='\033[2m'

show_banner(){
    echo -e "${error}"
    cat << "EOF"

                                                                               /$$$$$$                   
                                                                              /$$__  $$                  
    /$$$$$$/$$$$   /$$$$$$   /$$$$$$$  /$$$$$$$  /$$$$$$   /$$$$$$    /$$$$$$ | $$  \__//$$$$$$   /$$$$$$ 
    | $$_  $$_  $$ |____  $$ /$$_____/ /$$_____/ /$$__  $$ /$$__  $$ /$$__  $$| $$$$   /$$__  $$ /$$__  $$
    | $$ \ $$ \ $$  /$$$$$$$| $$      |  $$$$$$ | $$  \ $$| $$  \ $$| $$  \ $$| $$_/  | $$$$$$$$| $$  \__/
    | $$ | $$ | $$ /$$__  $$| $$       \____  $$| $$  | $$| $$  | $$| $$  | $$| $$    | $$_____/| $$      
    | $$ | $$ | $$|  $$$$$$$|  $$$$$$$ /$$$$$$$/| $$$$$$$/|  $$$$$$/|  $$$$$$/| $$    |  $$$$$$$| $$      
    |__/ |__/ |__/ \_______/ \_______/|_______/ | $$____/  \______/  \______/ |__/     \_______/|__/      
                                                | $$                                                      
                                                | $$                                                      
                                                |__/                                         made by kerlo                  
EOF
    echo -e "${NC}"
    echo -e "${white}"
}

show_banner

echo ""
echo -e "${NC}"
echo -e "${dim}$(date)${white}"
echo -e "${dim}User: ${white}$USER${NC}"

echo -e "${white}"
echo -e "[1] Random MAC Address"
echo -e " └─ [2] Manual MAC Address"
echo -e "     └─ [3] Credits"
echo -e "         └─ [4] Exit" 
echo -e ""
read -r -p "Select option [1-4]: " option

case $option in
    1)  
        show_banner
        echo -e "${white}--- Random MAC Address Generator ---${NC}\n"

        echo -e "${alert}Available Network Interfaces:${NC}"
        
        available_ifaces=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2}')
        
        for iface in $available_ifaces; do
            current_mac=$(cat /sys/class/net/"$iface"/address)
            echo -e " -> ${bold}$iface${NC} \t[Current: $current_mac]"
        done
        echo ""

        read -r -p "Select your network interface: " interface

        if [ ! -d "/sys/class/net/$interface" ]; then
            echo -e "\n${error}[!] Error: Interface '$interface' not found.${NC}"
            exit 1
        fi

        echo -e "\n${dim}[*] Generating random MAC...${NC}"

        rand_hex=$(od -An -N5 -t x1 /dev/urandom | tr -d ' ')
        suffix=$(echo "$rand_hex" | sed 's/.\{2\}/&:/g' | sed 's/:$//')
        new_mac="02:$suffix"
        
        echo -e "${dim}[*] Target MAC: ${white}$new_mac${NC}"
        echo -e "${dim}[*] Taking interface down...${NC}"
        sudo ip link set dev "$interface" down
        
        echo -e "${dim}[*] Applying new MAC address...${NC}"
        if sudo ip link set dev "$interface" address "$new_mac"; then
            sudo ip link set dev "$interface" up
            echo -e "${working}[V] Success! Interface is back up.${NC}"
            echo -e "\n${bold}New Configuration for $interface:${NC}"
            ip link show "$interface" | grep "link/ether" | awk '{print "MAC: " $2}'
        else
            echo -e "${error}[X] Failed to change MAC address.${NC}"
            echo -e "${dim}Possible reasons: Driver doesn't support spoofing or permission denied.${NC}"
            sudo ip link set dev "$interface" up
        fi
        ;;

    2)
        echo "Manual mode not implemented yet."
        ;;

    3)  echo "Credits are not implemented yet."
        ;;

    4)
        echo -e "Thank you for using ${bold}macspoofer${NC}!"
        exit
        ;;
        
    *) 
        echo -e "${error}Invalid option.${NC}"
        ;;
esac
