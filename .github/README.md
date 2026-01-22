```
                                                                               /$$$$$$                   
                                                                              /$$__  $$                 
    /$$$$$$/$$$$   /$$$$$$   /$$$$$$$  /$$$$$$$  /$$$$$$   /$$$$$$   /$$$$$$  | $$  \__//$$$$$$   /$$$$$$ 
    | $$_  $$_  $$ |____  $$ /$$_____/ /$$_____/ /$$__  $$ /$$__  $$ /$$__  $$| $$$$   /$$__  $$ /$$__  $$
    | $$ \ $$ \ $$  /$$$$$$$| $$      |  $$$$$$ | $$  \ $$| $$  \ $$| $$  \ $$| $$_/  | $$$$$$$$| $$  \__/
    | $$ | $$ | $$ /$$__  $$| $$       \____  $$| $$  | $$| $$  | $$| $$  | $$| $$    | $$_____/| $$      
    | $$ | $$ | $$|  $$$$$$$|  $$$$$$$ /$$$$$$$/| $$$$$$$/|  $$$$$$/|  $$$$$$/| $$    |  $$$$$$$| $$      
    |__/ |__/ |__/ \_______/ \_______/|_______/ | $$____/  \______/  \______/ |__/     \_______/|__/      
                                                | $$                                                      
                                                | $$                                                      
                                                |__/    
```
### A dependency-free Bash script to manually change your network interface MAC address on any Linux distro.

## Why using macspoofer?
* **Zero Dependencies:** It does not require installing third-party tools. It uses standard commands found on almost every Linux distribution (`ip`, `od`, `sed`, `grep`).
* **Universal Compatibility:** Works on Arch, Debian, Fedora, Alpine, and others out of the box.
* **Privacy Focused:** Helps maintain anonymity on public Wi-Fi networks by masking your hardware address.
* **Safe Randomization:** Automatically handles the "Locally Administered" and "Unicast" bits (sets the first byte to `02`) to ensure the generated MAC address is valid and accepted by drivers.
* **Transparent:** The code is minimal and easy to audit, unlike complex compiled binaries.

## Usage
1. Clone the repository:
    ```bash
    git clone https://github.com/Kerlooo/macspoofer
    ```
2. Enter the macspoofer directory:
   ```bash
   cd macspoofer
   ```
3. Make the script executable:
   ```bash
   chmod +x spoofer.sh
   ```
4. Run the script (you need root privileges):
   ```bash
   sudo ./spoofer.sh
   ```

---

## Available options:
- [X] Random MAC Address 
- [x] Manual Mode

## How it Works 
The script interacts directly with the Linux kernel via the ip command.
For random generation, it reads raw bytes from /dev/urandom. To prevent connectivity issues, the script ensures the first octet follows IEEE 802 standards for local addresses (setting the second least significant bit to 1), resulting in a prefix like 02, 06, 0A, or 0E.

## Roadmap
Current development status and planned features:

- [x] **Random MAC Generator:** Fully functional with safe bit handling (unicast/local).
- [x] **Dependency Free:** Zero external tools required, pure Bash implementation.
- [x] **Manual Mode:** Implement custom MAC input with regex format validation.
- [ ] **Restore Function:** Option to revert to the original hardware address without rebooting.
- [ ] **CLI Arguments:** Support non-interactive mode (e.g., `./spoofer.sh --random wlan0`) for automation.
- [ ] **Persistence:** Systemd service integration to spoof address at boot.

## License
This guide is distributed under the **Creative Commons Attribution 4.0 International (CC BY 4.0)** license.

**You are free to:**
- **Share** — copy and redistribute the material in any medium or format.
- **Adapt** — remix, transform, and build upon the material for any purpose, even commercially.

**Under the following terms:**
- **Attribution** — You must give appropriate credit, provide a link to the license, and indicate if changes were made.

For more details, see the [LICENSE](../LICENSE) file or visit [creativecommons.org](https://creativecommons.org/licenses/by/4.0/).
