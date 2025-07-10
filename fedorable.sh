#!/bin/bash

set -euo pipefail
trap 'echo -e "\n ERROR at line $LINENO: $BASH_COMMAND (exit code: $?)" >&2' ERR

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please run with sudo or as the root user." 1>&2
   exit 1
fi

# Set PATH and environment variables
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
ACTUAL_USER=${SUDO_USER:-$(logname)}
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)
USER_ID=$(id -u "$ACTUAL_USER")
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus"

# Dialog settings
HEIGHT=20
WIDTH=90
CHOICE_HEIGHT=10
BACKTITLE="Fedorable v2.0 - A Fedora Post Install Setup Util for GNOME - By Smittix - https://smittix.net"
TITLE="Please Make a Selection"
MENU="Please Choose one of the following options:"
OH_MY_ZSH_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
LOG_FILE="setup_log.txt"

# Ensure log file is writable
if ! touch "$LOG_FILE" &>/dev/null; then
    echo "❌ Cannot write to log file $LOG_FILE" >&2
    exit 1
fi

log_action() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

if ! command -v dialog &>/dev/null; then
    dnf install -y dialog || { log_action "Failed to install dialog. Exiting."; exit 1; }
    log_action "Installed dialog."
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

OPTIONS=(
    1 "Enable RPM Fusion"
    2 "Update Firmware"
    3 "Speed up DNF"
    4 "Enable Flathub"
    5 "Install Software"
    6 "Install Oh-My-ZSH"
    7 "Install Extras"
    8 "Hardware"
    9 "Customise"
    10 "Quit"
)

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
    fwupdmgr get-devices
    fwupdmgr refresh --force
    fwupdmgr get-updates
    fwupdmgr update -y
    local fw_update_status=$?
    set -e

    if [[ $fw_update_status -ne 0 ]]; then
        notify "Firmware update encountered errors. Please check manually."
    else
        notify "System firmware updated."
    fi

    if dialog --yesno "Reboot now to apply firmware updates?" 10 40; then
        reboot
    else
        log_action "Reboot skipped after firmware update."
        clear
    fi
}

speed_up_dnf() {
    grep -q '^max_parallel_downloads=' /etc/dnf/dnf.conf || echo 'max_parallel_downloads=10' >> /etc/dnf/dnf.conf
    notify "DNF configuration updated for parallel downloads."
}

enable_flatpak() {
        export PATH=$PATH:/usr/bin:/usr/local/bin
        export XDG_DATA_DIRS=/var/lib/flatpak/exports/share:/usr/share:/usr/local/share
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        flatpak update -y
        if [[ -f ./assets/flatpak-install.sh ]]; then
            bash ./assets/flatpak-install.sh || echo "flatpak-install.sh exited with an error"
        else
            echo "flatpak-install.sh not found"
        fi
    notify "Flatpak enabled and user apps installed."
}

install_software() {
    if [[ -f ./assets/dnf-packages.txt ]]; then
        dnf install -y $(< ./assets/dnf-packages.txt)
        notify "Software packages installed."
    else
        dialog --msgbox "Package list not found at ./assets/dnf-packages.txt" 10 50
        log_action "Package list missing."
    fi
}

install_oh_my_zsh() {
    dnf install -y zsh curl git

    if sudo -u "$ACTUAL_USER" test -d "$ACTUAL_HOME/.oh-my-zsh"; then
        log_action "Oh-My-Zsh is already installed for user $ACTUAL_USER"
    else
        sudo -u "$ACTUAL_USER" sh -c "RUNZSH=no CHSH=no $(curl -fsSL $OH_MY_ZSH_URL)"
    fi

    ZSH_PATH=$(command -v zsh)
    if ! grep -qxF "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" >> /etc/shells
        log_action "Added $ZSH_PATH to /etc/shells"
    fi

    sudo chsh -s "$ZSH_PATH" "$ACTUAL_USER"

    ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$ACTUAL_HOME/.oh-my-zsh/custom}"

    for plugin in zsh-autosuggestions zsh-autocomplete zsh-history-substring-search zsh-syntax-highlighting; do
        PLUGIN_DIR="$ZSH_CUSTOM_DIR/plugins/$plugin"
        if [ ! -d "$PLUGIN_DIR" ]; then
            sudo -u "$ACTUAL_USER" env GIT_TERMINAL_PROMPT=0 git clone "https://github.com/zsh-users/$plugin.git" "$PLUGIN_DIR" || \
            log_action "Failed to clone $plugin plugin. Check network or credentials."
        fi
    done

    if ! sudo -u "$ACTUAL_USER" command -v starship &>/dev/null; then
        curl -sS https://starship.rs/install.sh | sudo -u "$ACTUAL_USER" sh -s -- -y
    fi

    if ! grep -qxF 'eval "$(starship init zsh)"' "$ACTUAL_HOME/.zshrc"; then
        echo 'eval "$(starship init zsh)"' | sudo -u "$ACTUAL_USER" tee -a "$ACTUAL_HOME/.zshrc" >/dev/null
    fi

    sudo -u "$ACTUAL_USER" sed -i \
        -e 's/plugins=(git)/plugins=(dnf aliases git zsh-autosuggestions zsh-autocomplete zsh-history-substring-search zsh-syntax-highlighting)/' \
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
    dnf install -y iosevka-term-fonts jetbrains-mono-fonts-all terminus-fonts terminus-fonts-console google-noto-fonts-common fira-code-fonts cabextract xorg-x11-font-utils fontconfig

    rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm || true

    sudo -u "$ACTUAL_USER" mkdir -p "$ACTUAL_HOME/.local/share/fonts/google"
    sudo -u "$ACTUAL_USER" wget -q -O "$ACTUAL_HOME/.local/share/fonts/google/google-fonts.zip" https://github.com/google/fonts/archive/main.zip
    sudo -u "$ACTUAL_USER" unzip -q "$ACTUAL_HOME/.local/share/fonts/google/google-fonts.zip" -d "$ACTUAL_HOME/.local/share/fonts/google"
    sudo -u "$ACTUAL_USER" rm -f "$ACTUAL_HOME/.local/share/fonts/google/google-fonts.zip"

    for font_repo in source-sans source-serif source-code-pro; do
        if ! sudo -u "$ACTUAL_USER" test -d "$ACTUAL_HOME/.local/share/fonts/adobe-fonts/$font_repo"; then
            sudo -u "$ACTUAL_USER" git clone --depth 1 "https://github.com/adobe-fonts/$font_repo.git" "$ACTUAL_HOME/.local/share/fonts/adobe-fonts/$font_repo"
        fi
    done

    sudo -u "$ACTUAL_USER" fc-cache -fv "$ACTUAL_HOME/.local/share/fonts"
    sudo -u "$ACTUAL_USER" fc-cache -fv

    if [[ ! -d /tmp/Tela-icon-theme ]]; then
        git clone https://github.com/vinceliuice/Tela-icon-theme.git /tmp/Tela-icon-theme
        bash /tmp/Tela-icon-theme/install.sh -a
        rm -rf /tmp/Tela-icon-theme
    fi
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.interface icon-theme "Tela-orange"

    if [[ ! -d /tmp/Qogir-icon-theme ]]; then
        git clone https://github.com/vinceliuice/Qogir-icon-theme.git /tmp/Qogir-icon-theme
        bash /tmp/Qogir-icon-theme/install.sh -c all -t all
        rm -rf /tmp/Qogir-icon-theme
    fi
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.interface icon-theme "Qogir"

    dnf install -y papirus-icon-theme
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.interface icon-theme "Papirus"

    notify "Extra packages, fonts, and icon themes installed."
}

install_intel_media_driver() {
    dnf install -y intel-media-driver
    notify "Intel media driver installed."
}

install_amd_codecs() {
    dnf install -y mesa-va-drivers mesa-vdpau-drivers
    notify "AMD hardware codecs installed."
}

install_nvidia_drivers() {
    dnf install -y akmod-nvidia
    notify "NVIDIA drivers installed. Please wait 5 minutes before rebooting."
    if dialog --yesno "Reboot now to enable NVIDIA drivers?" 10 40; then
        reboot
    else
        log_action "Reboot skipped after NVIDIA driver install."
    fi
}

set_hostname() {
    hostname=$(dialog --inputbox "Enter new hostname:" 10 50 3>&1 1>&2 2>&3 3>&-)
    if [[ "$hostname" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        hostnamectl set-hostname "$hostname"
        dialog --msgbox "Hostname set to $hostname" 10 50
    else
        dialog --msgbox "Invalid hostname." 10 50
    fi
}

setup_fonts() {
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans Regular 10'
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.interface font-name 'Noto Sans Regular 10'
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10'
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans Regular 10'
    notify "Custom fonts have been set."
}

customize_clock() {
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.interface clock-format '24h'
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.interface clock-show-date true
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.interface clock-show-seconds false
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.interface clock-show-weekday false
    notify "Clock format customized."
}

enable_window_buttons() {
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"
    notify "Window buttons enabled."
}

center_windows() {
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.mutter center-new-windows true
    notify "Windows will now be centered."
}

disable_auto_maximize() {
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set org.gnome.mutter auto-maximize false
    notify "Auto-maximize disabled."
}

perform_all() {
    setup_fonts
    customize_clock
    enable_window_buttons
    center_windows
    disable_auto_maximize
    dialog --msgbox "All customization steps completed." 10 50
}

while true; do
    CHOICE=$(dialog --clear \
    --backtitle "$BACKTITLE" \
    --title "$TITLE" \
    --nocancel \
    --menu "$MENU" \
    $HEIGHT $WIDTH $CHOICE_HEIGHT \
    "${OPTIONS[@]}" \
    2>&1 >/dev/tty || echo "")

    if [[ -z "$CHOICE" ]]; then
        log_action "No option selected (empty input). Returning to menu."
        continue
    fi

    clear
    case $CHOICE in
        1) enable_rpm_fusion ;;
        2) update_firmware ;;
        3) speed_up_dnf ;;
        4) enable_flatpak ;;
        5) install_software ;;
        6) install_oh_my_zsh ;;
        7) install_extras ;;
        8)
            while true; do
                HARDWARE_CHOICE=$(dialog --clear --backtitle "Hardware Drivers Installation" \
                    --title "Hardware Menu" \
                    --menu "Choose hardware to install drivers for:" 15 50 4 \
                    1 "Intel Media Driver" \
                    2 "AMD Hardware Codecs" \
                    3 "NVIDIA Drivers" \
                    4 "Back" \
                    2>&1 >/dev/tty)

                if [[ -z "$HARDWARE_CHOICE" ]]; then
                    log_action "No hardware option selected. Returning to main menu."
                    break
                fi

                case $HARDWARE_CHOICE in
                    1) install_intel_media_driver ;;
                    2) install_amd_codecs ;;
                    3) install_nvidia_drivers ;;
                    4) break ;;
                    *) dialog --msgbox "Invalid option. Please try again." 10 50 ;;
                esac
            done
            ;;
        9)
            while true; do
                CUSTOM_CHOICE=$(dialog --clear --backtitle "Fedora System Configuration" \
                    --title "Customization Menu" \
                    --nocancel \
                    --menu "Choose an option:" 15 50 8 \
                    1 "Set Hostname" \
                    2 "Setup Custom Fonts" \
                    3 "Customize Clock" \
                    4 "Enable Window Buttons" \
                    5 "Center Windows" \
                    6 "Disable Auto-Maximize" \
                    7 "Perform All Tasks" \
                    8 "Exit" \
                    2>&1 >/dev/tty)

                case $CUSTOM_CHOICE in
                    1) set_hostname ;;
                    2) setup_fonts ;;
                    3) customize_clock ;;
                    4) enable_window_buttons ;;
                    5) center_windows ;;
                    6) disable_auto_maximize ;;
                    7) perform_all ;;
                    8) break ;;
                    *) dialog --msgbox "Invalid option. Please try again." 10 50 ;;
                esac
            done
            ;;
        10)
            log_action "User chose to quit the script."
            exit 0
            ;;
        *)
            log_action "Invalid option selected: $CHOICE"
            ;;
    esac
done
