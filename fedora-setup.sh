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
         2 "Enable Better Fonts - Better font rendering by Dawid"
         3 "Speed up DNF - This enables fastestmirror, max downloads and deltarpms"
         4 "Enable Flatpak - Enables the Flatpak repository"
         5 "Install Common Software - Installs a bunch of my most used software (see git)"
         6 "Install Oh-My-ZSH"
         7 "Enable Tweaks, Extensions & Plugins"
	 8 "Quit")

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
        2)  echo "Enabling Better Fonts by Dawid"
            sudo -s dnf -y copr enable dawid/better_fonts
            sudo -s dnf install -y fontconfig-font-replacements
            sudo -s dnf install -y fontconfig-enhanced-defaults
            notify-send "Fonts prettified - enjoy!" --expire-time=10
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
            notify-send "Flatpak has now been enabled" --expire-time=10
           ;;
        5)  echo "Installing Software"
            sudo dnf install -y gnome-extensions-app gnome-tweaks gnome-shell-extension-appindicator vlc dropbox nautilus-dropbox dnfdragora audacious mscore-fonts-all neofetch cmatrix p7zip unzip gparted alacritty nikto nmap fira-code-fonts
            notify-send "Software has been installed" --expire-time=10
           ;;
        6)  echo "Installing Oh-My-Zsh"
            sudo dnf -y install zsh util-linux-user
            sh -c "$(curl -fsSL $OH_MY_ZSH_URL)"
            echo "change shell to ZSH"
            chsh -s "$(which zsh)"
            notify-send "Oh-My-Zsh is ready to rock n roll" --expire-time=10
           ;;
        7)  echo "Installing Tweaks, extensions & plugins"
            sudo dnf groupupdate -y sound-and-video
            sudo dnf install -y libdvdcss
            sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,ugly-\*,base} gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel ffmpeg gstreamer-ffmpeg
            sudo dnf install -y lame\* --exclude=lame-devel
            sudo dnf group upgrade -y --with-optional Multimedia
	    sudo dnf install -y jetbrains-mono-fonts-all
	    sudo dnf copr enable peterwu/iosekva -y
	    sudo dnf search iosevka
	    sudo dnf install iosevka-term-fonts
            notify-send "All done" --expire-time=10
	   ;;
        8)
          exit 0
          ;;
    esac
done
