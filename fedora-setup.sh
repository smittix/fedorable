#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
HEIGHT=20
WIDTH=90
CHOICE_HEIGHT=4
BACKTITLE="Fedora Setup Util - By Osiris - https://lsass.co.uk"
TITLE="Please Make a selection"
MENU="Please Choose one of the following options:"

#Other variables
OH_MY_ZSH_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

#Check to see if Dialog is installed, if not install it - Thanks Kinkz_nl
if [ $(rpm -q dialog 2>/dev/null | grep -c "is not installed") -eq 1 ]; then
sudo dnf install -y dialog
fi

OPTIONS=(1 "Enable RPM Fusion - Enables the RPM Fusion repos for your specific version"
         2 "Update Firmware - If your system supports fw update delivery"
         3 "Speed up DNF - This enables fastestmirror, max downloads and deltarpms"
         4 "Enable Flatpak - Enables the Flatpak repo and installs packages"
         5 "Install Software - Installs a bunch of my most used software"
         6 "Install Oh-My-ZSH"
         7 "Install Starship Prompt - INSTALL AFTER Oh-My-Zsh ONLY"
         8 "Install Extras - Themes Fonts and Codecs"
         9 "Install Nvidia - Install akmod nvidia drivers"
         10 "Gaming on Linux - Install software needed to game on Linux"
	 11 "Quit")

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
        2)  echo "Updating Firmware"
            sudo fwupdmgr get-devices 
            sudo fwupdmgr refresh --force 
            sudo fwupdmgr get-updates 
            sudo fwupdmgr update
           ;;
        3)  echo "Speeding Up DNF"
            echo 'fastestmirror=1' | sudo tee -a /etc/dnf/dnf.conf
            echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf
            echo 'deltarpm=true' | sudo tee -a /etc/dnf/dnf.conf
            notify-send "Your DNF config has now been amended" --expire-time=10
           ;;
        4)  echo "Enabling Flatpak"
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
            flatpak update
            source 'flatpak-install.sh'
            notify-send "Flatpak has now been enabled" --expire-time=10
           ;;
        5)  echo "Installing Software"
            sudo dnf install -y $(cat dnf-packages.txt)
            notify-send "Software has been installed" --expire-time=10
           ;;
        6)  echo "Installing Oh-My-Zsh"
            sudo dnf -y install zsh util-linux-user
            sh -c "$(curl -fsSL $OH_MY_ZSH_URL)"
            echo "change shell to ZSH"
            chsh -s "$(which zsh)"
            notify-send "Oh-My-Zsh is ready to rock n roll" --expire-time=10
           ;;
        7)  echo "Installing Starship Prompt"
            curl -sS https://starship.rs/install.sh | sh
            echo "eval "$(starship init zsh)"" >> ~/.zshrc
            notify-send "Starship Prompt Activated" --expire-time=10
           ;;
        8)  echo "Installing Extras"
            sudo dnf groupupdate -y sound-and-video
            sudo dnf install -y libdvdcss
            sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,ugly-\*,base} gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel ffmpeg gstreamer-ffmpeg
            sudo dnf install -y lame\* --exclude=lame-devel
            sudo dnf group upgrade -y --with-optional Multimedia
	    sudo dnf copr enable peterwu/iosevka -y
            sudo -s dnf -y copr enable dawid/better_fonts
            sudo dnf update -y
            sudo -s dnf install -y fontconfig-font-replacements
            sudo -s dnf install -y fontconfig-enhanced-defaults
	    sudo dnf update -y
	    sudo dnf install -y iosevka-term-fonts jetbrains-mono-fonts-all gnome-shell-theme-flat-remix flat-remix-icon-theme flat-remix-theme terminus-fonts terminus-fonts-console google-noto-fonts-common mscore-fonts-all fira-code-fonts
            notify-send "All done" --expire-time=10
           ;;
        9)  echo "Installing Nvidia Driver Akmod-Nvidia"
            sudo dnf install -y akmod-nvidia
            notify-send "All done" --expire-time=10
	       ;;
        10) echo "Installing Gaming Software"
            sudo dnf install -y wine
            sudo dnf install -y steam
            sudo dnf install -y lutris
            sudo dnf install -y mangohud
            sudo dnf install -y gamemode
            sudo dnf install -y goverlay
            # Flatpak 
            flatpak install flathub com.heroicgameslauncher.hgl -y
            flatpak install flathub net.davidotek.pupgui2 -y
            notify-send "Gaming software successfully installed" --expire-time=10
        ;;
        11)
          exit 0
          ;;
    esac
done
