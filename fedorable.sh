#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
HEIGHT=20
WIDTH=90
CHOICE_HEIGHT=4
BACKTITLE="Fedorable a Fedora Post Install Setup Util for GNOME - By Smittix - https://lsass.co.uk"
TITLE="Please Make a selection"
MENU="Please Choose one of the following options:"

#Other variables
OH_MY_ZSH_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

#Check to see if Dialog is installed, if not install it - Thanks Kinkz_nl
if [ $(rpm -q dialog 2>/dev/null | grep -c "is not installed") -eq 1 ]; then
sudo dnf install -y dialog
fi

OPTIONS=(1 "Enable RPM Fusion - Enables the RPM Fusion repos for your specific version"
         2 "Update Firmware - If your system supports FW update delivery"
         3 "Speed up DNF - Sets max parallel downloads to 10"
         4 "Enable Flatpak - Enables the Flatpak repo and installs packages located in flatpak-packages.txt"
         5 "Install Software - Installs software located in dnf-packages.txt"
         6 "Install Oh-My-ZSH - Installs Oh-My-ZSH & Starship Prompt"
         7 "Install Extras - Themes Fonts and Codecs"
         8 "Install Nvidia - Install akmod Nvidia drivers"
	     9 "Quit")

while [ "$CHOICE -ne 4" ]; do
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
        1)  echo "Enabling RPM Fusion"
            sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
	    sudo dnf upgrade --refresh
            sudo dnf groupupdate -y core
            sudo dnf install -y rpmfusion-free-release-tainted
            sudo dnf install -y dnf-plugins-core
            notify-send "RPM Fusion Enabled" --expire-time=10
           ;;
        2)  echo "Updating System Firmware"
            #Updates firmware where available
            sudo fwupdmgr get-devices 
            sudo fwupdmgr refresh --force 
            sudo fwupdmgr get-updates 
            sudo fwupdmgr update
           ;;
        3)  echo "Speeding Up DNF"
            #Sets max parallel downloads to 10
            echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf
            notify-send "Your DNF config has now been amended" --expire-time=10
           ;;
        4)  echo "Enabling Flatpak"
            #Enables the flatpak repository and installs packages located within flatpak-packages.txt
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
            flatpak update
            source flatpak-install.sh
            notify-send "Flatpak has now been enabled" --expire-time=10
           ;;
        5)  echo "Installing Software"
            #Installs packages that are listed in the dnf-packages.txt file
            sudo dnf install -y $(cat dnf-packages.txt)
            notify-send "Software has been installed" --expire-time=10
           ;;
        6)  echo "Installing Oh-My-Zsh with Starship"
            #Installs Oh-My-ZSH along with the Starship prompt
            sudo dnf -y install zsh curl util-linux-user
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            echo "change shell to ZSH"
            chsh -s "$(which zsh)"
            curl -sS https://starship.rs/install.sh | sh
            notify-send "Oh-My-Zsh is ready to rock n roll" --expire-time=10
            echo 'eval "$(starship init zsh)"' >> ~/.zshrc
            notify-send "Oh-My-Zsh is ready to rock n roll" --expire-time=10
           ;;
        7)  echo "Installing Extras"
            #Media Codecs
            sudo dnf groupupdate -y sound-and-video
            sudo dnf swap ffmpeg-free ffmpeg --allowerasing
            sudo dnf install -y libdvdcss
            sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,ugly-\*,base} gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel ffmpeg gstreamer-ffmpeg
            sudo dnf install -y lame\* --exclude=lame-devel
            sudo dnf group upgrade -y --with-optional Multimedia
	    sudo dnf config-manager --set-enabled fedora-cisco-openh264
            sudo dnf install -y gstreamer1-plugin-openh264 mozilla-openh264
	    #Iosevka Font Copr
            sudo dnf copr enable peterwu/iosevka -y
            sudo dnf update -y
	    #Themes and Icons
            sudo dnf install -y papirus-icon-theme gnome-shell-theme-flat-remix gnome-shell-theme-yaru 
            #Fonts
     	    sudo dnf install -y iosevka-term-fonts jetbrains-mono-fonts-all terminus-fonts terminus-fonts-console google-noto-fonts-common fira-code-fonts cabextract xorg-x11-font-utils fontconfig
            #Microsoft Core Fonts
            sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
            notify-send "All done" --expire-time=10
           ;;
        8)  echo "Installing Nvidia Driver Akmod-Nvidia"
            sudo dnf install -y akmod-nvidia
            notify-send "Please wait 5 minutes until rebooting" --expire-time=10
	       ;;
        9)
          exit 0
          ;;
    esac
done
