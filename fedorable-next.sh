#!/bin/bash
#
# Fedorable v2.6 - Fedora Post Install Setup for GNOME
# Always menu unless --install-all, hang-free extras, optimised
# By Smittix - https://smittix.net
#

set -euo pipefail
trap 'echo -e "\nERROR at line $LINENO: $BASH_COMMAND (exit code: $?)" >&2' ERR
trap cleanup EXIT

########################################
# Config Section
########################################
MIN_FEDORA_VERSION=40
LOG_FILE="fedorable_$(date +%F_%H-%M-%S).log"
DRY_RUN=false
NO_DIALOG=false
INSTALL_ALL=false

# External URLs & Repos
OH_MY_ZSH_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
STARSHIP_URL="https://starship.rs/install.sh"
ADOBE_FONTS=("source-sans" "source-serif" "source-code-pro")

########################################
# Colour Setup
########################################
if [[ -t 1 ]]; then
    BOLD="\033[1m"
    GREEN="\033[32m"
    RESET="\033[0m"
else
    BOLD=""; GREEN=""; RESET=""
fi

########################################
# Logging
########################################
exec > >(tee -a "$LOG_FILE") 2>&1
log_action() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"; }
cleanup() { [[ -d /tmp/fedorable_tmp ]] && rm -rf /tmp/fedorable_tmp; }

########################################
# CLI Help
########################################
show_help() {
    cat <<EOF
${BOLD}Fedorable v2.6 - Fedora Post Install Setup${RESET}
By Smittix - https://smittix.net

Usage:
  sudo ./fedorable.sh [options]

Options:
  --help               Show this help menu and exit
  --dry-run            Print commands without executing them
  --no-dialog          Run without interactive menus
  --install-all        Run all steps without menus
EOF
}

########################################
# CLI Argument Handling
########################################
for arg in "$@"; do
    case $arg in
        --help) show_help; exit 0 ;;
        --dry-run) DRY_RUN=true ;;
        --no-dialog) NO_DIALOG=true ;;
        --install-all) INSTALL_ALL=true ;;
        *) echo "Unknown option: $arg"; exit 1 ;;
    esac
done

########################################
# Pre-flight Checks
########################################
if [[ $EUID -ne 0 ]]; then echo "Run as root"; exit 1; fi
FEDORA_VER=$(rpm -E %fedora)
ACTUAL_USER=${SUDO_USER:-$(logname)}
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)
USER_ID=$(id -u "$ACTUAL_USER")
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus"
mkdir -p /tmp/fedorable_tmp

########################################
# Helpers
########################################
run_cmd() { $DRY_RUN && echo "[DRY RUN] $*" || eval "$@"; }
gset() { run_cmd sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set "$1" "$2" "$3"; }
notify() { ! $NO_DIALOG && command -v dialog &>/dev/null && dialog --msgbox "$1" 8 50 || echo "$1"; log_action "$1"; }

########################################
# System Setup
########################################
enable_rpm_fusion() { run_cmd dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$FEDORA_VER".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$FEDORA_VER".noarch.rpm; run_cmd dnf upgrade --refresh -y; notify "RPM Fusion enabled."; }
update_firmware() { run_cmd fwupdmgr refresh --force; run_cmd fwupdmgr update -y || notify "Check firmware manually."; }
speed_up_dnf() { grep -q '^max_parallel_downloads=' /etc/dnf/dnf.conf || echo 'max_parallel_downloads=10' >> /etc/dnf/dnf.conf; notify "DNF speed optimised."; }
enable_flatpak() {
    run_cmd flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    ( run_cmd flatpak update -y ) &
    ( [[ -f ./assets/flatpak-install.sh ]] && bash ./assets/flatpak-install.sh ) &
    wait
    notify "Flathub enabled and Flatpak apps installed."
}

########################################
# Software Installation
########################################
install_software() { [[ -f ./assets/dnf-packages.txt ]] && run_cmd dnf install -y $(< ./assets/dnf-packages.txt) && notify "Software installed." || notify "Package list not found."; }
install_oh_my_zsh() { run_cmd dnf install -y zsh curl git; curl -fsSL "$OH_MY_ZSH_URL" -o /tmp/fedorable_tmp/ohmyzsh.sh; run_cmd sudo -u "$ACTUAL_USER" sh -c "RUNZSH=no CHSH=no bash /tmp/fedorable_tmp/ohmyzsh.sh"; install_starship; notify "Oh-My-ZSH & Starship installed."; }
install_starship() { curl -fsSL "$STARSHIP_URL" -o /tmp/fedorable_tmp/starship.sh; run_cmd sudo -u "$ACTUAL_USER" sh /tmp/fedorable_tmp/starship.sh -y; }

########################################
# Extras (Hang-Free)
########################################
install_extras() {
    run_cmd dnf swap ffmpeg-free ffmpeg --allowerasing
    run_cmd dnf update @multimedia --setopt="install_weak_deps=False" -y
    run_cmd dnf install -y gstreamer1-plugin-openh264 mozilla-openh264

    bg_jobs=0

    if [[ ! -d "$ACTUAL_HOME/.local/share/fonts/google" ]]; then
        (
            mkdir -p "$ACTUAL_HOME/.local/share/fonts/google"
            wget -q -O "$ACTUAL_HOME/.local/share/fonts/google/google-fonts.zip" https://github.com/google/fonts/archive/main.zip
            unzip -q "$ACTUAL_HOME/.local/share/fonts/google/google-fonts.zip" -d "$ACTUAL_HOME/.local/share/fonts/google"
            rm -f "$ACTUAL_HOME/.local/share/fonts/google/google-fonts.zip"
        ) & bg_jobs=$((bg_jobs+1))
    else
        log_action "Google Fonts already installed, skipping."
    fi

    for repo in "${ADOBE_FONTS[@]}"; do
        if [[ ! -d "$ACTUAL_HOME/.local/share/fonts/adobe-fonts/$repo" ]]; then
            (
                run_cmd sudo -u "$ACTUAL_USER" git clone --depth 1 "https://github.com/adobe-fonts/$repo.git" "$ACTUAL_HOME/.local/share/fonts/adobe-fonts/$repo"
            ) & bg_jobs=$((bg_jobs+1))
        else
            log_action "Adobe font $repo already installed, skipping."
        fi
    done

    if [[ $bg_jobs -gt 0 ]]; then
        wait
        run_cmd sudo -u "$ACTUAL_USER" fc-cache -fv
        notify "Fonts and codecs installed."
    else
        notify "Fonts already installed. Only codecs updated."
    fi
}

########################################
# Hardware
########################################
install_intel_media_driver() { run_cmd dnf install -y intel-media-driver && notify "Intel driver installed."; }
install_amd_codecs() { run_cmd dnf install -y mesa-va-drivers mesa-vdpau-drivers && notify "AMD codecs installed."; }
install_nvidia_drivers() { run_cmd dnf install -y akmod-nvidia && notify "NVIDIA drivers installed."; }

########################################
# Customisation
########################################
set_hostname() { local hn; hn=$(dialog --inputbox "Enter hostname:" 10 50 3>&1 1>&2 2>&3 3>&-); [[ "$hn" =~ ^[a-zA-Z0-9.-]+$ ]] && run_cmd hostnamectl set-hostname "$hn" && notify "Hostname set." || notify "Invalid hostname."; }
setup_fonts() { gset org.gnome.desktop.interface document-font-name 'Noto Sans Regular 10'; gset org.gnome.desktop.interface font-name 'Noto Sans Regular 10'; gset org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10'; notify "Fonts set."; }
customize_clock() { gset org.gnome.desktop.interface clock-format '24h'; gset org.gnome.desktop.interface clock-show-date true; notify "Clock customised."; }
enable_window_buttons() { gset org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"; notify "Buttons enabled."; }
center_windows() { gset org.gnome.mutter center-new-windows true; notify "Windows centered."; }
disable_auto_maximize() { gset org.gnome.mutter auto-maximize false; notify "Auto-maximise disabled."; }
perform_all() { setup_fonts; customize_clock; enable_window_buttons; center_windows; disable_auto_maximize; }

########################################
# Menu or Install-All
########################################
if [[ "$INSTALL_ALL" == true ]]; then
    enable_rpm_fusion
    update_firmware
    speed_up_dnf
    enable_flatpak
    install_software
    install_oh_my_zsh
    install_extras
    install_intel_media_driver
    install_amd_codecs
    install_nvidia_drivers
    perform_all
    notify "All tasks completed."
else
    while true; do
        CHOICE=$(dialog --clear --title "Fedorable v2.6" --menu "Choose an option:" 20 70 10 \
            1 "System Setup" \
            2 "Software Installation" \
            3 "Hardware Drivers" \
            4 "Customisation" \
            5 "Quit" \
            2>&1 >/dev/tty)
        case $CHOICE in
            1) while true; do
                   SYS_CHOICE=$(dialog --clear --title "System Setup" --menu "Choose an option:" 15 50 6 \
                       1 "Enable RPM Fusion" \
                       2 "Update Firmware" \
                       3 "Optimise DNF Speed" \
                       4 "Enable Flathub" \
                       5 "Back" \
                       2>&1 >/dev/tty)
                   case $SYS_CHOICE in
                       1) enable_rpm_fusion ;;
                       2) update_firmware ;;
                       3) speed_up_dnf ;;
                       4) enable_flatpak ;;
                       5) break ;;
                   esac
               done ;;
            2) while true; do
                   SW_CHOICE=$(dialog --clear --title "Software Installation" --menu "Choose an option:" 15 50 6 \
                       1 "Install Software Packages" \
                       2 "Install Oh-My-ZSH" \
                       3 "Install Extras" \
                       4 "Back" \
                       2>&1 >/dev/tty)
                   case $SW_CHOICE in
                       1) install_software ;;
                       2) install_oh_my_zsh ;;
                       3) install_extras ;;
                       4) break ;;
                   esac
               done ;;
            3) while true; do
                   HW_CHOICE=$(dialog --clear --title "Hardware Drivers" --menu "Choose an option:" 15 50 6 \
                       1 "Install Intel Media Driver" \
                       2 "Install AMD Codecs" \
                       3 "Install NVIDIA Drivers" \
                       4 "Back" \
                       2>&1 >/dev/tty)
                   case $HW_CHOICE in
                       1) install_intel_media_driver ;;
                       2) install_amd_codecs ;;
                       3) install_nvidia_drivers ;;
                       4) break ;;
                   esac
               done ;;
            4) while true; do
                   CUST_CHOICE=$(dialog --clear --title "Customisation" --menu "Choose an option:" 15 50 9 \
                       1 "Set Hostname" \
                       2 "Setup Fonts" \
                       3 "Customise Clock" \
                       4 "Enable Window Buttons" \
                       5 "Center Windows" \
                       6 "Disable Auto-Maximise" \
                       7 "Apply All" \
                       8 "Back" \
                       2>&1 >/dev/tty)
                   case $CUST_CHOICE in
                       1) set_hostname ;;
                       2) setup_fonts ;;
                       3) customize_clock ;;
                       4) enable_window_buttons ;;
                       5) center_windows ;;
                       6) disable_auto_maximize ;;
                       7) perform_all ;;
                       8) break ;;
                   esac
               done ;;
            5) exit 0 ;;
        esac
    done
fi
