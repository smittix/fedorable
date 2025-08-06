#!/bin/bash

set -euo pipefail
trap 'echo -e "\n ERROR at line $LINENO: $BASH_COMMAND (exit code: $?)" >&2' ERR

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please run with sudo or as the root user." 1>&2
   exit 1
fi

# Variables
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
ACTUAL_USER=${SUDO_USER:-$(logname)}
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)
USER_ID=$(id -u "$ACTUAL_USER")
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus"
HEIGHT=20
WIDTH=90
CHOICE_HEIGHT=10
BACKTITLE="Fedorable v2.0 - Fedora Post Install Setup for GNOME - By Smittix - https://smittix.net"
OH_MY_ZSH_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
LOG_FILE="setup_log.txt"

# Ensure log file writable
if ! touch "$LOG_FILE" &>/dev/null; then
    echo "Cannot write to log file $LOG_FILE" >&2
    exit 1
fi

log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Install dialog if missing
if ! command -v dialog &>/dev/null; then
    dnf install -y dialog || { log_action "Failed to install dialog. Exiting."; exit 1; }
fi

notify() {
    local message=$1
    local expire_time=${2:-10}
    DISPLAY_VAL=$(sudo -u "$ACTUAL_USER" printenv DISPLAY 2>/dev/null || echo ":0")
    if command -v notify-send &>/dev/null && [[ -n "$DISPLAY_VAL" ]]; then
        sudo -u "$ACTUAL_USER" DISPLAY=$DISPLAY_VAL DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
            notify-send "$message" --expire-time="$expire_time" || dialog --msgbox "$message" 8 50
    else
        dialog --msgbox "$message" 8 50
    fi
    log_action "$message"
}

########################################
# Functions: System Setup
########################################
enable_rpm_fusion() {
    dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    dnf upgrade --refresh -y
    dnf group upgrade -y core
    dnf install -y rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted dnf-plugins-core
    notify "RPM Fusion repositories enabled."
}

update_firmware() {
    set +e
    fwupdmgr refresh --force
    fwupdmgr update -y
    local status=$?
    set -e
    [[ $status -ne 0 ]] && notify "Firmware update errors. Please check manually." || notify "System firmware updated."
    if dialog --yesno "Reboot now to apply firmware updates?" 10 40; then reboot; fi
}

speed_up_dnf() {
    grep -q '^max_parallel_downloads=' /etc/dnf/dnf.conf || echo 'max_parallel_downloads=10' >> /etc/dnf/dnf.conf
    notify "DNF configuration updated for faster downloads."
}

enable_flatpak() {
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak update -y
    [[ -f ./assets/flatpak-install.sh ]] && bash ./assets/flatpak-install.sh
    notify "Flathub enabled and Flatpak apps installed."
}

########################################
# Functions: Software Installation
########################################
install_software() {
    [[ -f ./assets/dnf-packages.txt ]] && dnf install -y $(< ./assets/dnf-packages.txt) && notify "Software installed." \
        || dialog --msgbox "Package list not found." 10 50
}

install_oh_my_zsh() {
    dnf install -y zsh curl git
    if ! sudo -u "$ACTUAL_USER" test -d "$ACTUAL_HOME/.oh-my-zsh"; then
        sudo -u "$ACTUAL_USER" sh -c "RUNZSH=no CHSH=no $(curl -fsSL $OH_MY_ZSH_URL)"
    fi
    ZSH_PATH=$(command -v zsh)
    grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" >> /etc/shells
    sudo chsh -s "$ZSH_PATH" "$ACTUAL_USER"
    ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$ACTUAL_HOME/.oh-my-zsh/custom}"
    for plugin in zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting; do
        [[ ! -d "$ZSH_CUSTOM_DIR/plugins/$plugin" ]] && \
        sudo -u "$ACTUAL_USER" git clone "https://github.com/zsh-users/$plugin.git" "$ZSH_CUSTOM_DIR/plugins/$plugin"
    done
    if ! sudo -u "$ACTUAL_USER" command -v starship &>/dev/null; then
        curl -sS https://starship.rs/install.sh | sudo -u "$ACTUAL_USER" sh -s -- -y
    fi
    grep -qxF 'eval "$(starship init zsh)"' "$ACTUAL_HOME/.zshrc" || \
        echo 'eval "$(starship init zsh)"' | sudo -u "$ACTUAL_USER" tee -a "$ACTUAL_HOME/.zshrc" >/dev/null
    sudo -u "$ACTUAL_USER" sed -i \
        -e 's/plugins=(git)/plugins=(dnf aliases git zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting)/' \
        -e 's/ZSH_THEME="robbyrussell"/ZSH_THEME="jonathan"/' \
        "$ACTUAL_HOME/.zshrc"
    notify "Oh-My-ZSH, plugins, and Starship prompt installed."
}

install_extras() {
    dnf swap ffmpeg-free ffmpeg --allowerasing
    dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
    dnf install -y gstreamer1-plugin-openh264 mozilla-openh264
    dnf copr enable peterwu/iosevka -y
    dnf update -y
    dnf install -y iosevka-term-fonts jetbrains-mono-fonts-all terminus-fonts terminus-fonts-console google-noto-fonts-common fira-code-fonts \
        cabextract xorg-x11-font-utils fontconfig papirus-icon-theme
    rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm || true
    sudo -u "$ACTUAL_USER" mkdir -p "$ACTUAL_HOME/.local/share/fonts/google"
    sudo -u "$ACTUAL_USER" wget -q -O "$ACTUAL_HOME/.local/share/fonts/google/google-fonts.zip" https://github.com/google/fonts/archive/main.zip
    sudo -u "$ACTUAL_USER" unzip -q "$ACTUAL_HOME/.local/share/fonts/google/google-fonts.zip" -d "$ACTUAL_HOME/.local/share/fonts/google"
    sudo -u "$ACTUAL_USER" rm -f "$ACTUAL_HOME/.local/share/fonts/google/google-fonts.zip"
    for repo in source-sans source-serif source-code-pro; do
        [[ ! -d "$ACTUAL_HOME/.local/share/fonts/adobe-fonts/$repo" ]] && \
        sudo -u "$ACTUAL_USER" git clone --depth 1 "https://github.com/adobe-fonts/$repo.git" "$ACTUAL_HOME/.local/share/fonts/adobe-fonts/$repo"
    done
    sudo -u "$ACTUAL_USER" fc-cache -fv
    [[ ! -d /tmp/Tela-icon-theme ]] && git clone https://github.com/vinceliuice/Tela-icon-theme.git /tmp/Tela-icon-theme && bash /tmp/Tela-icon-theme/install.sh -a && rm -rf /tmp/Tela-icon-theme
    [[ ! -d /tmp/Qogir-icon-theme ]] && git clone https://github.com/vinceliuice/Qogir-icon-theme.git /tmp/Qogir-icon-theme && bash /tmp/Qogir-icon-theme/install.sh -c all -t all && rm -rf /tmp/Qogir-icon-theme
    notify "Extra packages, fonts, and icon themes installed."
}

########################################
# Functions: Hardware Drivers
########################################
install_intel_media_driver() { dnf install -y intel-media-driver && notify "Intel media driver installed."; }
install_amd_codecs() { dnf install -y mesa-va-drivers mesa-vdpau-drivers && notify "AMD hardware codecs installed."; }
install_nvidia_drivers() {
    dnf install -y akmod-nvidia && notify "NVIDIA drivers installed. Please wait 5 minutes before rebooting."
    if dialog --yesno "Reboot now to enable NVIDIA drivers?" 10 40; then reboot; fi
}

########################################
# Functions: Customisation
########################################
set_hostname() {
    hostname=$(dialog --inputbox "Enter new hostname:" 10 50 3>&1 1>&2 2>&3 3>&-)
    [[ "$hostname" =~ ^[a-zA-Z0-9.-]+$ ]] && hostnamectl set-hostname "$hostname" && dialog --msgbox "Hostname set to $hostname" 10 50 \
        || dialog --msgbox "Invalid hostname." 10 50
}
setup_fonts() {
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
        gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans Regular 10'
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
        gsettings set org.gnome.desktop.interface font-name 'Noto Sans Regular 10'
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
        gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10'
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
        gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans Regular 10'
    notify "Custom fonts have been set."
}
customize_clock() {
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
        gsettings set org.gnome.desktop.interface clock-format '24h'
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
        gsettings set org.gnome.desktop.interface clock-show-date true
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
        gsettings set org.gnome.desktop.interface clock-show-seconds false
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
        gsettings set org.gnome.desktop.interface clock-show-weekday false
    notify "Clock format customised."
}
enable_window_buttons() { sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close" && notify "Window buttons enabled."; }
center_windows() { sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.mutter center-new-windows true && notify "Windows will now be centered."; }
disable_auto_maximize() { sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.mutter auto-maximize false && notify "Auto-maximize disabled."; }
perform_all() { setup_fonts; customize_clock; enable_window_buttons; center_windows; disable_auto_maximize; dialog --msgbox "All customisations applied." 10 50; }

########################################
# Main Menu Loop
########################################
while true; do
    CHOICE=$(dialog --clear --backtitle "$BACKTITLE" --title "Main Menu" --nocancel --menu "Choose an option:" \
        $HEIGHT $WIDTH $CHOICE_HEIGHT \
        1 "System Setup" \
        2 "Software Installation" \
        3 "Hardware Drivers" \
        4 "Customisation" \
        5 "Quit" \
        2>&1 >/dev/tty)

    case $CHOICE in
        1) # System Setup Menu
            while true; do
                SYS_CHOICE=$(dialog --clear --backtitle "$BACKTITLE" --title "System Setup" --menu "Choose an option:" 15 50 6 \
                    1 "Enable RPM Fusion" \
                    2 "Update Firmware" \
                    3 "Optimise DNF Speed" \
                    4 "Enable Flathub" \
                    5 "Back to Main Menu" \
                    2>&1 >/dev/tty)
                case $SYS_CHOICE in
                    1) enable_rpm_fusion ;;
                    2) update_firmware ;;
                    3) speed_up_dnf ;;
                    4) enable_flatpak ;;
                    5) break ;;
                esac
            done
            ;;
        2) # Software Installation Menu
            while true; do
                SW_CHOICE=$(dialog --clear --backtitle "$BACKTITLE" --title "Software Installation" --menu "Choose an option:" 15 50 6 \
                    1 "Install Software Packages" \
                    2 "Install Oh-My-ZSH" \
                    3 "Install Extras (Fonts & Codecs)" \
                    4 "Back to Main Menu" \
                    2>&1 >/dev/tty)
                case $SW_CHOICE in
                    1) install_software ;;
                    2) install_oh_my_zsh ;;
                    3) install_extras ;;
                    4) break ;;
                esac
            done
            ;;
        3) # Hardware Drivers Menu
            while true; do
                HW_CHOICE=$(dialog --clear --backtitle "$BACKTITLE" --title "Hardware Drivers" --menu "Choose an option:" 15 50 6 \
                    1 "Install Intel Media Driver" \
                    2 "Install AMD Hardware Codecs" \
                    3 "Install NVIDIA Drivers" \
                    4 "Back to Main Menu" \
                    2>&1 >/dev/tty)
                case $HW_CHOICE in
                    1) install_intel_media_driver ;;
                    2) install_amd_codecs ;;
                    3) install_nvidia_drivers ;;
                    4) break ;;
                esac
            done
            ;;
        4) # Customisation Menu
            while true; do
                CUST_CHOICE=$(dialog --clear --backtitle "$BACKTITLE" --title "Customisation" --menu "Choose an option:" 15 50 9 \
                    1 "Set Hostname" \
                    2 "Setup Custom Fonts" \
                    3 "Customise Clock" \
                    4 "Enable Window Buttons" \
                    5 "Center New Windows" \
                    6 "Disable Auto-Maximise" \
                    7 "Apply All Customisations" \
                    8 "Back to Main Menu" \
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
            done
            ;;
        5) exit 0 ;;
    esac
done
