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

INSTALL_PATH="/usr/local/bin/macspoofer"
STATE_DIR="/var/lib/macspoofer"

show_banner() {
    clear
    echo -e "${error}"
    cat << "EOF"

                                                                                /$$$$$$
                                                                               /$$__  $$
     /$$$$$$/$$$$   /$$$$$$   /$$$$$$$  /$$$$$$$  /$$$$$$   /$$$$$$   /$$$$$$ | $$  \__//$$$$$$   /$$$$$$
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

list_ifaces() {
    echo -e "${alert}Available Network Interfaces:${NC}"

    local available_ifaces iface current_mac
    available_ifaces="$(ip -o link show | awk -F': ' '$2 != "lo" {print $2}')"

    for iface in ${available_ifaces}; do
        current_mac="$(cat "/sys/class/net/${iface}/address")"
        echo -e " -> ${bold}${iface}${NC} \t[Current: ${current_mac}]"
    done
    echo ""
}

# Sets the global variable "interface"
select_iface() {
    list_ifaces

    read -r -p "Select your network interface: " interface

    if [ ! -d "/sys/class/net/${interface}" ]; then
        echo -e "\n${error}[!] Error: Interface '${interface}' not found.${NC}"
        exit 1
    fi
}

apply_mac() {
    local iface="$1"
    local new_mac="$2"

    echo -e "${dim}[*] Target MAC: ${white}${new_mac}${NC}"
    echo -e "${dim}[*] Taking interface down...${NC}"
    ip link set dev "${iface}" down

    echo -e "${dim}[*] Applying new MAC address...${NC}"
    if ip link set dev "${iface}" address "${new_mac}"; then
        ip link set dev "${iface}" up
        echo -e "${working}[+] Success! Interface is back up.${NC}"
        echo -e "\n${bold}New Configuration for ${iface}:${NC}"
        ip link show "${iface}" | awk '/link\/ether/ {print "MAC: " $2}'
    else
        echo -e "${error}[-] Failed to change MAC address.${NC}"
        ip link set dev "${iface}" up
        return 1
    fi
}

# Saves the current MAC of an interface, only if not already saved
save_original_mac() {
    local iface="$1"
    local state_file="${STATE_DIR}/${iface}"

    [ -f "${state_file}" ] && return 0

    mkdir -p "${STATE_DIR}"
    cat "/sys/class/net/${iface}/address" > "${state_file}"
}

# Prints the original MAC of an interface, or nothing if unknown
get_original_mac() {
    local iface="$1"
    local state_file="${STATE_DIR}/${iface}"
    local perm_mac current_mac
    current_mac="$(cat "/sys/class/net/${iface}/address")"

    # Kernel exposes "permaddr" when the current MAC differs from the hardware one
    perm_mac="$(ip link show dev "${iface}" | awk '{for (i = 1; i < NF; i++) if ($i == "permaddr") print $(i + 1)}')"
    if [ -n "${perm_mac}" ]; then
        echo "${perm_mac}"
    elif [ -f "${state_file}" ]; then
        cat "${state_file}"
    elif [ "$(cat "/sys/class/net/${iface}/addr_assign_type")" = "0" ]; then
        echo "${current_mac}"
    elif (( (0x${current_mac:0:2} & 0x02) == 0 )); then
        # Globally administered (vendor) address: spoofed ones are always local
        echo "${current_mac}"
    fi
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
echo -e "         └─ [4] Install macspoofer"
echo -e "             └─ [5] Credits"
echo -e "                 └─ [6] Exit"
echo -e ""
read -r -p "Select option [1-6]: " option

case "${option}" in
    1)
        show_banner
        echo -e "${white}--- Random MAC Address Generator ---${NC}\n"

        select_iface

        echo -e "\n${dim}[*] Generating random MAC...${NC}"

        rand_hex="$(od -An -N5 -t x1 /dev/urandom | tr -d ' ')"
        suffix="$(echo "${rand_hex}" | sed 's/.\{2\}/&:/g' | sed 's/:$//')"
        new_mac="02:${suffix}"

        save_original_mac "${interface}"
        apply_mac "${interface}" "${new_mac}"
        ;;

    2)
        show_banner
        echo -e "${white}--- Manual MAC Address Configuration ---${NC}\n"

        select_iface

        echo -e "\n${dim}Enter MAC address suffix (format: XX:XX:XX:XX:XX)${NC}"
        echo -e "${dim}The full MAC will be: 02:XX:XX:XX:XX:XX${NC}"
        read -r -p "MAC suffix: " mac_suffix

        if ! [[ "${mac_suffix}" =~ ^([0-9A-Fa-f]{2}:){4}[0-9A-Fa-f]{2}$ ]]; then
            echo -e "\n${error}[!] Error: Invalid MAC address format.${NC}"
            exit 1
        fi

        echo ""
        save_original_mac "${interface}"
        apply_mac "${interface}" "02:${mac_suffix}"
        ;;

    3)
        show_banner
        echo -e "${white}--- Restore Original MAC Address ---${NC}\n"

        select_iface

        original_mac="$(get_original_mac "${interface}")"
        current_mac="$(cat "/sys/class/net/${interface}/address")"

        if [ -z "${original_mac}" ]; then
            echo -e "\n${error}[!] Error: Original MAC address of '${interface}' is unknown.${NC}"
            exit 1
        fi

        if [ "${original_mac,,}" = "${current_mac,,}" ]; then
            echo -e "\n${working}[+] '${interface}' is already using its original MAC address (${original_mac}).${NC}"
            rm -f "${STATE_DIR}/${interface}"
            exit 0
        fi

        echo ""
        if apply_mac "${interface}" "${original_mac}"; then
            rm -f "${STATE_DIR}/${interface}"
        fi
        ;;
        
    4)
        show_banner
        echo -e "${white}--- Installing macspoofer ---${NC}\n"

        cp "$0" "${INSTALL_PATH}" || {
            echo -e "${error}[-] Failed to copy script.${NC}"
            exit 1
        }

        chmod +x "${INSTALL_PATH}"

        echo -e "${working}[+] Installed successfully!${NC}"
        echo -e "${dim}You can now run:${NC} ${bold}macspoofer${NC}"
        read -r -p "Press Enter to exit..."
        ;;

    5)
        show_banner
        echo -e "${white}--- Credits ---${NC}\n"
        echo -e "${bold}Developer:${NC} ${white}kerlo https://github.com/Kerlooo${NC}"
        echo -e "${bold}License:${NC} ${white}Creative Commons Attribution 4.0 International (CC BY 4.0)${NC}"
        echo -e "${bold}Thank you for using${NC} ${white}macspoofer${NC}!"
        read -r -p "Press Enter to exit..."
        ;;

    6)
        echo -e "Thank you for using ${bold}macspoofer${NC}!"
        exit 0
        ;;

    *)
        echo -e "${error}Invalid option.${NC}"
        exit 0
        ;;
esac