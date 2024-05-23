<h1 align="center">
  Fedorable - a post install helper script for the GNOME desktop environment.
</h1>
<p align="center">
  <img width="300" height="300" src="logo.png">
</p>

## What's all this then?

Fedorable is a personal script I created to help with post install tasks such as tweaks and software installs. It's written in Bash and utilises Dialog for a friendlier menu system. 

It is fully customisable by the user by either editing the script itself or changing the package selections within the flatpak-packages.txt or dnf-packages.txt files.

Dialog must be installed for the menu system to work and as such the script will check to see if Dialog is installed. If not, it will ask you to install it.

Scripts for Cinnamon and KDE will become available in the future.

## Usage
1. Set the script to be executable `chmod -x fedorable.sh`
2. Run the script `./fedorable.sh`
3. Enter user password when required (for installation of packages)

## Files

- **flatpak-packages.txt** - This file contains a list of all flat packages to install you can customise this with your choice of applications by application-id.
- **dnf-packages.txt** - This file contains a list of all applications that will be installed via the Fedora and RPMFusion repositories.

## Screenshot
![Screenshot](screenshot.png)
# Options

- ## Enable RPM Fusion
  - Enables RPM Fusion repositories using the official method from the RPM Fusion website. - [RPM Fusion](https://rpmfusion.org)
  > RPM Fusion provides software that the Fedora Project or Red Hat doesn't want to ship. That software is provided as precompiled RPMs for all current Fedora versions and current Red Hat Enterprise Linux or clones versions; you can use the RPM Fusion repositories with tools like yum and PackageKit.
- ## Update Firmware
  - **Updates firmware providing you have hardwar that supports it.**
- ## Speed up DNF
  - **Sets max parallel downloads to 10**
- ## Enable Flatpak and Packages
  ### Adds the flatpak repo, updates and installs the following packages (or what you have specified in flatpak-packages.txt)
  - **Signal Desktop** - [A cross platform secure messaging service](https://signal.org/en/download/)
  - **Obsidian** - [Obsidian is the private and flexible writing app that adapts to the way you think](https://obsidian.md/)
  - **Amberol** - [Amberol is a music player with no delusions of grandeur. If you just want to play music available on your local system then Amberol is the music player you are looking for.](https://apps.gnome.org/en-GB/Amberol/)
  - **Discord** - [The popular VoIP, IM and Social platform](https://discord.com)
  - **OrbVis** - [OrbVis is a real-time satellite tracking and visualisation application](https://github.com/wojciech-graj/OrbVis)
  - **Element** - [Decentralised, encrypted chat & collaboration powered by Matrix](https://element.io/)
  - **Spotify** - [Spotify is a digital music, podcast, and video service](https://spotify.com)
- ## Install Software
  ### Installs the following pieces of software (or the applications you specify in dnf-packages.txt)
    - **neofetch** - [CLI system information tool](http://www.figlet.org/)
    - **btop** - [CLI based system monitor](https://github.com/aristocratos/btop)
    - **gnome-extensions-app** - [GNOME extension management application](https://gitlab.gnome.org/GNOME/gnome-tweaks)
    - **gnome-tweaks** - [GNOME Tweak Tool](https://github.com/GNOME/gnome-tweaks)
    - **vlc**  - [A cross platform multimedia player](https://www.videolan.org/)
    - **p7zip** - [High compression archiving application](https://p7zip.sourceforge.net/)
    - **gimp** - [GNU Image Manipulation Program](https://gimp.org)
    - **libreoffice** - [Free and popular office suite with high compatibility to MS Office formats](https://www.libreoffice.org/)
    - **obs-studio** - [Free and open source software for video recording and live streaming](https://obsproject.com/)
    - **qBitorrent** - [The qBittorrent project aims to provide an open-source software alternative to µTorrent](https://www.qbittorrent.org/)
    - **Solaar** - [Linux Device Manager for Logitech Unifying Receivers and Devices](https://pwr-solaar.github.io/Solaar/)
    - **imhex** - [ImHex is a Hex Editor, a tool to display, decode and analyze binary data to reverse engineer their format, extract informations or patch values in them.](https://imhex.werwolv.net/)
    - **gpredict** - [Gpredict is a real time satellite tracking and orbit prediction program for the Linux desktop](https://github.com/csete/gpredict)
    - **kdenlive** - [Free and Open Source Video Editor](https://kdenlive.org/en/)
- ## Install Oh-My-ZSH with StarShip Prompt
  - **Installs Oh-My-Zsh** - [A ZSH configuration management framework](https://ohmyz.sh/)
  - **Installs the Starship prompt for ZSH** - [A popular cross-shell highly customisable prompt](https://starship.rs/)
  
- ## Install Extras
  ### Installs the following fonts
    - **iosevka-term-fonts** - [Iosevka Font](https://github.com/be5invis/Iosevka)
    - **jetbrains-mono-fonts-all** - [JetBrains Font](https://www.jetbrains.com/lp/mono/)
    - **terminus-fonts** - [Terminus Font](https://terminus-font.sourceforge.net/)
    - **terminus-fonts-console** - [Terminus Font](https://terminus-font.sourceforge.net/)
    - **google-noto-fonts-common** - [Google Noto Sans Font](https://fonts.google.com/noto/specimen/Noto+Sans)
    - **MScore fonts** - [ore fonts for the Web was a project started by Microsoft in 1996 to create a standard pack of fonts for the World Wide Web](https://mscorefonts2.sourceforge.net/)
    - **fira-code-fonts** - [Google Fira Code Font](https://fonts.google.com/specimen/Fira+Code)
  ### Installs the following extras
    - **Sound and video group**
    - **libdvdcss** - [libdvdcss is a simple library designed for accessing DVDs](https://videolan.videolan.me/libdvdcss/)
    - **gstreamer plugins** - [a framework for streaming media](https://github.com/GStreamer/gstreamer)
  ### Install Nvidia
    - **Installs the akmod-nvidia driver from the RPMFusion repo's** - [An akmod is a type of package similar to dkms. As you start your computer, the akmod system will check if there are any missing kmods and if so, rebuild a new kmod for you. Akmods have more overhead than regular kmod packages as they require a few development tools such as gcc and automake in order to be able to build new kmods locally](https://rpmfusion.org/Howto/NVIDIA#Akmods)
