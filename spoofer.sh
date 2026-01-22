#!/bin/bash

# Check root
if [ "${EUID}" -ne 0 ]; then
  echo "You need to run this script as root for changing MAC address."
  exit 1
fi

white="\033[1;37m"
error="\033[0;31m"
working="\033[0;32m"
alert="\033[1;33m"
NC="\033[0m"
bold="\033[1m"
dim="\033[2m"

show_banner() {
    clear
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
echo -e "${dim}User: ${white}${USER}${NC}"

echo -e "${white}"
echo -e "[1] Random MAC Address"
echo -e " └─ [2] Manual MAC Address"
echo -e "     └─ [3] Restore MAC Address"
echo -e "         └─ [4] Credits"
echo -e "             └─ [5] Exit"
echo -e ""
read -r -p "Select option [1-5]: " option

case "${option}" in
    1)
        show_banner
        echo -e "${white}--- Random MAC Address Generator ---${NC}\n"

        echo -e "${alert}Available Network Interfaces:${NC}"

        available_ifaces="$(ip -o link show | awk -F': ' '$2 != "lo" {print $2}')"

        for iface in ${available_ifaces}; do
            current_mac="$(cat "/sys/class/net/${iface}/address")"
            echo -e " -> ${bold}${iface}${NC} \t[Current: ${current_mac}]"
        done
        echo ""

        read -r -p "Select your network interface: " interface

        if [ ! -d "/sys/class/net/${interface}" ]; then
            echo -e "\n${error}[!] Error: Interface '${interface}' not found.${NC}"
            exit 1
        fi

        echo -e "\n${dim}[*] Generating random MAC...${NC}"

        rand_hex="$(od -An -N5 -t x1 /dev/urandom | tr -d ' ')"
        suffix="$(echo "${rand_hex}" | sed 's/.\{2\}/&:/g' | sed 's/:$//')"
        new_mac="02:${suffix}"

        echo -e "${dim}[*] Target MAC: ${white}${new_mac}${NC}"
        echo -e "${dim}[*] Taking interface down...${NC}"
        ip link set dev "${interface}" down

        echo -e "${dim}[*] Applying new MAC address...${NC}"
        if ip link set dev "${interface}" address "${new_mac}"; then
            ip link set dev "${interface}" up
            echo -e "${working}[+] Success! Interface is back up.${NC}"
            echo -e "\n${bold}New Configuration for ${interface}:${NC}"
            ip link show "${interface}" | awk '/link\/ether/ {print "MAC: " $2}'
        else
            echo -e "${error}[-] Failed to change MAC address.${NC}"
            echo -e "${dim}Possible reasons: Driver doesn't support spoofing or permission denied.${NC}"
            ip link set dev "${interface}" up
        fi
        ;;

    2)
        show_banner
        echo -e "${white}--- Manual MAC Address Configuration ---${NC}\n"

        echo -e "${alert}Available Network Interfaces:${NC}"

        available_ifaces="$(ip -o link show | awk -F': ' '$2 != "lo" {print $2}')"

        for iface in ${available_ifaces}; do
            current_mac="$(cat "/sys/class/net/${iface}/address")"
            echo -e " -> ${bold}${iface}${NC} \t[Current: ${current_mac}]"
        done
        echo ""

        read -r -p "Select your network interface: " interface

        if [ ! -d "/sys/class/net/${interface}" ]; then
            echo -e "\n${error}[!] Error: Interface '${interface}' not found.${NC}"
            exit 1
        fi

        echo -e "\n${dim}Enter MAC address suffix (format: XX:XX:XX:XX:XX)${NC}"
        echo -e "${dim}The full MAC will be: 02:XX:XX:XX:XX:XX${NC}"
        read -r -p "MAC suffix: " mac_suffix

        if ! [[ "${mac_suffix}" =~ ^([0-9A-Fa-f]{2}:){4}[0-9A-Fa-f]{2}$ ]]; then
            echo -e "\n${error}[!] Error: Invalid MAC address format.${NC}"
            exit 1
        fi

        new_mac="02:${mac_suffix}"

        echo -e "\n${dim}[*] Target MAC: ${white}${new_mac}${NC}"
        echo -e "${dim}[*] Taking interface down...${NC}"
        ip link set dev "${interface}" down

        echo -e "${dim}[*] Applying new MAC address...${NC}"
        if ip link set dev "${interface}" address "${new_mac}"; then
            ip link set dev "${interface}" up
            echo -e "${working}[+] Success! Interface is back up.${NC}"
            echo -e "\n${bold}New Configuration for ${interface}:${NC}"
            ip link show "${interface}" | awk '/link\/ether/ {print "MAC: " $2}'
        else
            echo -e "${error}[-] Failed to change MAC address.${NC}"
            ip link set dev "${interface}" up
        fi
        ;;

    3)
        echo -e "${error}Restore MAC Address isn't implemented yet.${NC}"
        read -r -p "Press Enter to exit..."
        ;;

    4)
        show_banner
        echo -e "${white}--- Credits ---${NC}\n"
        echo -e "${bold}Developer:${NC} ${white}kerlo https://github.com/Kerlooo${NC}"
        echo -e "${bold}License:${NC} ${white}Creative Commons Attribution 4.0 International (CC BY 4.0)${NC}"
        echo -e "${bold}Thank you for using${NC} ${white}macspoofer${NC}!"
        read -r -p "Press Enter to exit..."
        ;;

    5)
        echo -e "Thank you for using ${bold}macspoofer${NC}!"
        exit 0
        ;;

    *)
        echo -e "${error}Invalid option.${NC}"
        ;;
esac
