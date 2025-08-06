#!/bin/bash
#
# Fedorable v3.8 - Fedora Post Install Setup for GNOME
# Perfect centering, Cancel/Esc safe, skip-on-cancel in perform_all
# Confirmation before big installs, silent skip on cancel
# By Smittix - https://smittix.net
#

set -euo pipefail
trap 'echo -e "\nERROR at line $LINENO: $BASH_COMMAND (exit code: $?)" >&2' ERR
trap cleanup EXIT

########################################
# Config
########################################
LOG_FILE="fedorable_$(date +%F_%H-%M-%S).log"
DRY_RUN=false
NO_DIALOG=false
INSTALL_ALL=false

OH_MY_ZSH_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
STARSHIP_URL="https://starship.rs/install.sh"
ADOBE_FONTS=("source-sans" "source-serif" "source-code-pro")

########################################
# Colours
########################################
if [[ -t 1 ]]; then
    BOLD="\033[1m"
    RESET="\033[0m"
else
    BOLD=""; RESET=""
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
${BOLD}Fedorable v3.8 - Fedora Post Install Setup${RESET}
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
# CLI Args
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
# Pre-flight
########################################
if [[ $EUID -ne 0 ]]; then echo "Run as root"; exit 1; fi
FEDORA_VER=$(rpm -E %fedora)
ACTUAL_USER=${SUDO_USER:-$(logname)}
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)
USER_ID=$(id -u "$ACTUAL_USER")
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus"
mkdir -p /tmp/fedorable_tmp

if ! command -v dialog &>/dev/null; then
    echo "Installing 'dialog'..."
    dnf install -y dialog
fi

########################################
# Dynamic sizing
########################################
TERM_HEIGHT=$(tput lines)
TERM_WIDTH=$(tput cols)
MENU_HEIGHT=$((TERM_HEIGHT - 10))
MENU_WIDTH=$((TERM_WIDTH - 10))
CHOICE_HEIGHT=10
ROW=$(( (TERM_HEIGHT - MENU_HEIGHT) / 2 ))
COL=$(( (TERM_WIDTH - MENU_WIDTH) / 2 ))

########################################
# Helpers
########################################
run_cmd() { $DRY_RUN && echo "[DRY RUN] $*" || eval "$@"; }
gset() { run_cmd sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set "$1" "$2" "$3"; }
notify() {
    if ! $NO_DIALOG && command -v dialog &>/dev/null; then
        dialog --begin 0 0 --msgbox "$1" 8 50
    else
        echo "$1"
    fi
    log_action "$1"
}
confirm_action() {
    dialog --begin "$ROW" "$COL" --yesno "$1" 8 50
    local ret=$?
    [[ $ret -ne 0 ]] && return 1
    return 0
}
input_box() {
    local result
    result=$(dialog --begin "$ROW" "$COL" --inputbox "$1" 10 50 3>&1 1>&2 2>&3 3>&-)
    RET=$?
    [[ $RET -ne 0 ]] && return 1
    echo "$result"
}

########################################
# System Setup
########################################
enable_rpm_fusion() {
    run_cmd dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$FEDORA_VER".noarch.rpm \
                          https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$FEDORA_VER".noarch.rpm
    run_cmd dnf upgrade --refresh -y
    notify "RPM Fusion enabled."
}
update_firmware() { run_cmd fwupdmgr refresh --force; run_cmd fwupdmgr update -y || notify "Check firmware manually."; }
speed_up_dnf() { grep -q '^max_parallel_downloads=' /etc/dnf/dnf.conf || echo 'max_parallel_downloads=10' >> /etc/dnf/dnf.conf; notify "DNF speed optimised."; }
enable_flatpak() {
    confirm_action "Enable Flathub repository and optionally update Flatpaks?" || return
    run_cmd flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    notify "Flathub repository added."
    if dialog --begin 0 0 --yesno "Do you want to update existing Flatpaks now?" 8 50; then
        ( run_cmd flatpak update --noninteractive --assumeyes --no-related ) &
    fi
    if [[ -f ./assets/flatpak-install.sh ]]; then
        bash ./assets/flatpak-install.sh &
    fi
    wait
    notify "Flathub enabled and Flatpak processing complete."
}

########################################
# Software
########################################
install_software() { [[ -f ./assets/dnf-packages.txt ]] && run_cmd dnf install -y $(< ./assets/dnf-packages.txt) && notify "Software installed." || notify "Package list not found."; }
install_oh_my_zsh() {
    confirm_action "Install Oh-My-ZSH with plugins and Starship prompt?" || return
    run_cmd dnf install -y zsh curl git
    curl -fsSL "$OH_MY_ZSH_URL" -o /tmp/fedorable_tmp/ohmyzsh.sh
    run_cmd sudo -u "$ACTUAL_USER" sh -c "RUNZSH=no CHSH=no bash /tmp/fedorable_tmp/ohmyzsh.sh"
    install_starship
    notify "Oh-My-ZSH & Starship installed."
}
install_starship() { curl -fsSL "$STARSHIP_URL" -o /tmp/fedorable_tmp/starship.sh; run_cmd sudo -u "$ACTUAL_USER" sh /tmp/fedorable_tmp/starship.sh -y; }
install_extras() {
    confirm_action "Install extras (codecs, fonts)?" || return
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
    fi
    for repo in "${ADOBE_FONTS[@]}"; do
        if [[ ! -d "$ACTUAL_HOME/.local/share/fonts/adobe-fonts/$repo" ]]; then
            (
                run_cmd sudo -u "$ACTUAL_USER" git clone --depth 1 "https://github.com/adobe-fonts/$repo.git" "$ACTUAL_HOME/.local/share/fonts/adobe-fonts/$repo"
            ) & bg_jobs=$((bg_jobs+1))
        fi
    done
    if [[ $bg_jobs -gt 0 ]]; then
        wait
        run_cmd sudo -u "$ACTUAL_USER" fc-cache -fv
    fi
    notify "Fonts and codecs installed."
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
set_hostname() {
    local hn
    hn=$(input_box "Enter hostname:") || return
    [[ "$hn" =~ ^[a-zA-Z0-9.-]+$ ]] && run_cmd hostnamectl set-hostname "$hn" && notify "Hostname set."
}
setup_fonts() { gset org.gnome.desktop.interface document-font-name 'Noto Sans Regular 10'; gset org.gnome.desktop.interface font-name 'Noto Sans Regular 10'; gset org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10'; notify "Fonts set."; }
customize_clock() { gset org.gnome.desktop.interface clock-format '24h'; gset org.gnome.desktop.interface clock-show-date true; notify "Clock customised."; }
enable_window_buttons() { gset org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"; notify "Buttons enabled."; }
center_windows() { gset org.gnome.mutter center-new-windows true; notify "Windows centered."; }
disable_auto_maximize() { gset org.gnome.mutter auto-maximize false; notify "Auto-maximise disabled."; }
perform_all() {
    enable_rpm_fusion
    update_firmware
    speed_up_dnf
    enable_flatpak || true
    install_software
    install_oh_my_zsh || true
    install_extras || true
    install_intel_media_driver
    install_amd_codecs
    install_nvidia_drivers
    set_hostname || true
    setup_fonts
    customize_clock
    enable_window_buttons
    center_windows
    disable_auto_maximize
}

########################################
# Menu or Install-All
########################################
if [[ "$INSTALL_ALL" == true ]]; then
    perform_all
    notify "All tasks completed."
else
    while true; do
        CHOICE=$(dialog --begin "$ROW" "$COL" --clear --title "Fedorable v3.8" --menu "Choose an option:" $MENU_HEIGHT $MENU_WIDTH $CHOICE_HEIGHT \
            1 "System Setup" \
            2 "Software Installation" \
            3 "Hardware Drivers" \
            4 "Customisation" \
            5 "Quit" \
            2>&1 >/dev/tty)
        RET=$?
        [[ $RET -ne 0 ]] && exit 0
        case $CHOICE in
            1) while true; do
                   SYS_CHOICE=$(dialog --begin "$ROW" "$COL" --clear --title "System Setup" --menu "Choose an option:" $MENU_HEIGHT $MENU_WIDTH $CHOICE_HEIGHT \
                       1 "Enable RPM Fusion" \
                       2 "Update Firmware" \
                       3 "Optimise DNF Speed" \
                       4 "Enable Flathub" \
                       5 "Back" \
                       2>&1 >/dev/tty)
                   RET=$?
                   [[ $RET -ne 0 ]] && break
                   case $SYS_CHOICE in
                       1) enable_rpm_fusion ;;
                       2) update_firmware ;;
                       3) speed_up_dnf ;;
                       4) enable_flatpak ;;
                       5) break ;;
                   esac
               done ;;
            2) while true; do
                   SW_CHOICE=$(dialog --begin "$ROW" "$COL" --clear --title "Software Installation" --menu "Choose an option:" $MENU_HEIGHT $MENU_WIDTH $CHOICE_HEIGHT \
                       1 "Install Software Packages" \
                       2 "Install Oh-My-ZSH" \
                       3 "Install Extras" \
                       4 "Back" \
                       2>&1 >/dev/tty)
                   RET=$?
                   [[ $RET -ne 0 ]] && break
                   case $SW_CHOICE in
                       1) install_software ;;
                       2) install_oh_my_zsh ;;
                       3) install_extras ;;
                       4) break ;;
                   esac
               done ;;
            3) while true; do
                   HW_CHOICE=$(dialog --begin "$ROW" "$COL" --clear --title "Hardware Drivers" --menu "Choose an option:" $MENU_HEIGHT $MENU_WIDTH $CHOICE_HEIGHT \
                       1 "Install Intel Media Driver" \
                       2 "Install AMD Codecs" \
                       3 "Install NVIDIA Drivers" \
                       4 "Back" \
                       2>&1 >/dev/tty)
                   RET=$?
                   [[ $RET -ne 0 ]] && break
                   case $HW_CHOICE in
                       1) install_intel_media_driver ;;
                       2) install_amd_codecs ;;
                       3) install_nvidia_drivers ;;
                       4) break ;;
                   esac
               done ;;
            4) while true; do
                   CUST_CHOICE=$(dialog --begin "$ROW" "$COL" --clear --title "Customisation" --menu "Choose an option:" $MENU_HEIGHT $MENU_WIDTH $CHOICE_HEIGHT \
                       1 "Set Hostname" \
                       2 "Setup Fonts" \
                       3 "Customise Clock" \
                       4 "Enable Window Buttons" \
                       5 "Center Windows" \
                       6 "Disable Auto-Maximise" \
                       7 "Apply All Customisations" \
                       8 "Back" \
                       2>&1 >/dev/tty)
                   RET=$?
                   [[ $RET -ne 0 ]] && break
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
