#!/bin/bash

# Regenerates the OUI database embedded at the end of spoofer.sh.
# Maintainer tool only: spoofer.sh itself does not need curl or network access.
#
# Usage: tools/update-oui.sh [path/to/oui.txt]
# Without arguments, the IEEE MA-L registry is downloaded.

set -euo pipefail

OUI_URL="https://standards-oui.ieee.org/oui/oui.txt"
MARKER="__OUI_DATA__"
END_MARKER="__OUI_END__"

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
spoofer="${repo_dir}/spoofer.sh"
source_file="${1:-}"

if [ -z "${source_file}" ]; then
    source_file="$(mktemp)"
    trap 'rm -f "${source_file}"' EXIT

    echo "[*] Downloading ${OUI_URL}..."
    # IEEE rejects non-browser clients
    curl -fsSL \
        -A "Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0" \
        -H "Accept: text/html,text/plain,*/*" \
        -H "Accept-Language: en-US,en;q=0.5" \
        -o "${source_file}" "${OUI_URL}"
fi

if ! grep -q "^${MARKER}$" "${spoofer}"; then
    echo "[!] Error: marker ${MARKER} not found in ${spoofer}." >&2
    exit 1
fi

# Output: "<OUI> <Vendor>", only for common consumer network hardware vendors
oui_data="$(tr -d '\r' < "${source_file}" | awk -F'\t+' '
    /\(hex\)/ {
        oui = $1
        sub(/ .*/, "", oui)
        gsub("-", "", oui)

        name = tolower($2)
        sub(/[ \t]+$/, "", name)

        vendor = ""
        if      (name ~ /^apple, inc/)                       vendor = "Apple"
        else if (name ~ /^(asustek)/)                        vendor = "ASUS"
        else if (name ~ /^azurewave/)                        vendor = "AzureWave"
        else if (name ~ /^broadcom/)                         vendor = "Broadcom"
        else if (name ~ /^dell (inc|technologies)|^dell$/)   vendor = "Dell"
        else if (name ~ /^google, inc/)                      vendor = "Google"
        else if (name ~ /^hewlett packard$|^hp inc/)         vendor = "HP"
        else if (name ~ /^huawei (technologies|device)/)     vendor = "Huawei"
        else if (name ~ /^intel (corporat|wireless)/)        vendor = "Intel"
        else if (name ~ /^lenovo|^lcfc/)                     vendor = "Lenovo"
        else if (name ~ /^lite-?on technology/)              vendor = "Liteon"
        else if (name ~ /^mediatek/)                         vendor = "MediaTek"
        else if (name ~ /^microsoft (corporation|corp)/)     vendor = "Microsoft"
        else if (name ~ /^qualcomm/)                         vendor = "Qualcomm"
        else if (name ~ /^raspberry pi/)                     vendor = "RaspberryPi"
        else if (name ~ /^realtek/)                          vendor = "Realtek"
        else if (name ~ /^samsung electronics/)              vendor = "Samsung"
        else if (name ~ /^tp-link/)                          vendor = "TP-Link"
        else if (name ~ /^xiaomi/)                           vendor = "Xiaomi"

        if (vendor != "" && oui ~ /^[0-9A-F]{6}$/) print oui, vendor
    }' | sort -u -k2,2 -k1,1)"

if [ -z "${oui_data}" ]; then
    echo "[!] Error: no OUI parsed from ${source_file}." >&2
    exit 1
fi

tmp_spoofer="$(mktemp)"
sed "/^${MARKER}$/q" "${spoofer}" > "${tmp_spoofer}"
printf '%s\n' "${oui_data}" "${END_MARKER}" >> "${tmp_spoofer}"
cat "${tmp_spoofer}" > "${spoofer}"
rm -f "${tmp_spoofer}"

echo "[+] Updated ${spoofer} with $(wc -l <<< "${oui_data}") OUIs:"
awk '{print $2}' <<< "${oui_data}" | uniq -c | sort -rn
