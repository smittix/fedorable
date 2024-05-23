#!/bin/bash

# Set PATH
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

# Dialog dimensions
HEIGHT=20
WIDTH=90
CHOICE_HEIGHT=10

# Titles and messages
BACKTITLE="Fedorable - A Fedora Post Install Setup Util for GNOME - By Smittix - https://lsass.co.uk"
TITLE="Please Make a Selection"
MENU="Please Choose one of the following options:"

# Other variables
OH_MY_ZSH_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
LOG_FILE="setup_log.txt"

# Log function
log_action() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a $LOG_FILE
}

# Check for dialog installation
if ! rpm -q dialog &>/dev/null; then
    sudo dnf install -y dialog || { log_action "Failed to install dialog. Exiting."; exit 1; }
    log_action "Installed dialog."
fi

# Options for the menu
OPTIONS=(
    1 "Enable RPM Fusion - Enables the RPM Fusion repos for your specific version"
    2 "Update Firmware - If your system supports FW update delivery"
    3 "Speed up DNF - Sets max parallel downloads to 10"
    4 "Enable Flatpak - Enables the Flatpak repo and installs packages located in flatpak-packages.txt"
    5 "Install Software - Installs software located in dnf-packages.txt"
    6 "Install Oh-My-ZSH - Installs Oh-My-ZSH & Starship Prompt"
    7 "Install Extras - Themes, Fonts, and Codecs"
    8 "Install Nvidia - Install akmod Nvidia drivers"
    9 "Quit"
)

# Function to display notifications
notify() {
    local message=$1
    local expire_time=${2:-10}
    if command -v notify-send &>/dev/null; then
        notify-send "$message" --expire-time="$expire_time"
    fi
    log_action "$message"
}

# Function to handle RPM Fusion setup
enable_rpm_fusion() {
    echo "Enabling RPM Fusion"
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf upgrade --refresh -y
    sudo dnf groupupdate -y core
    sudo dnf install -y rpmfusion-free-release-tainted dnf-plugins-core
    notify "RPM Fusion Enabled"
}

# Function to update firmware
update_firmware() {
    echo "Updating System Firmware"
    sudo fwupdmgr get-devices
    sudo fwupdmgr refresh --force
    sudo fwupdmgr get-updates
    sudo fwupdmgr update
    notify "System Firmware Updated"
}

# Function to speed up DNF
speed_up_dnf() {
    echo "Speeding Up DNF"
    echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf
    notify "Your DNF config has now been amended"
}

# Function to enable Flatpak
enable_flatpak() {
    echo "Enabling Flatpak"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak update -y
    if [ -f flatpak-install.sh ]; then
        source flatpak-install.sh
    else
        log_action "flatpak-install.sh not found"
    fi
    notify "Flatpak has now been enabled"
}

# Function to install software
install_software() {
    echo "Installing Software"
    if [ -f dnf-packages.txt ]; then
        sudo dnf install -y $(cat dnf-packages.txt)
        notify "Software has been installed"
    else
        log_action "dnf-packages.txt not found"
    fi
}

# Function to install Oh-My-Zsh and Starship
install_oh_my_zsh() {
    echo "Installing Oh-My-Zsh with Starship"
    sudo dnf install -y zsh curl util-linux-user
    sh -c "$(curl -fsSL $OH_MY_ZSH_URL)" "" --unattended
    chsh -s "$(which zsh)"
    curl -sS https://starship.rs/install.sh | sh
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc
    notify "Oh-My-Zsh is ready to rock n roll"
}

# Function to install extras
install_extras() {
    echo "Installing Extras"
    sudo dnf groupupdate -y sound-and-video
    sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
    sudo dnf install -y libdvdcss
    sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,ugly-\*,base} gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel ffmpeg gstreamer-ffmpeg
    sudo dnf install -y lame\* --exclude=lame-devel
    sudo dnf group upgrade -y --with-optional Multimedia
    sudo dnf config-manager --set-enabled fedora-cisco-openh264
    sudo dnf install -y gstreamer1-plugin-openh264 mozilla-openh264
    sudo dnf copr enable peterwu/iosevka -y
    sudo dnf update -y
    sudo dnf install -y iosevka-term-fonts jetbrains-mono-fonts-all terminus-fonts terminus-fonts-console google-noto-fonts-common fira-code-fonts cabextract xorg-x11-font-utils fontconfig
    sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
    notify "All done"
}

# Function to install Nvidia drivers
install_nvidia() {
    echo "Installing Nvidia Driver Akmod-Nvidia"
    sudo dnf install -y akmod-nvidia
    notify "Please wait 5 minutes until rebooting"
}

# Main loop
while true; do
    CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --nocancel \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

    clear
    case $CHOICE in
        1) enable_rpm_fusion ;;
        2) update_firmware ;;
        3) speed_up_dnf ;;
        4) enable_flatpak ;;
        5) install_software ;;
        6) install_oh_my_zsh ;;
        7) install_extras ;;
        8) install_nvidia ;;
        9) log_action "User chose to quit the script."; exit 0 ;;
        *) log_action "Invalid option selected: $CHOICE";;
    esac
done
