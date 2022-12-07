# Fedora-Setup a Post Install Helper Script

## What's all this then?

Fedora-Setup is a personal script I created to help with post install tasks such as tweaks and software installs. It's written in Bash and utilises Dialog for a friendlier menu system.

Dialog must be installed for the menu system to work and as such the script will check to see if Dialog is installed. If not, it will ask you to install it.



## Screenshot

![Screenshot](fedora-setup-screenshot.png)

## Options

- **Enable RPM Fusion**
  
  - Enables RPM Fusion repositories using the official method from the RPM Fusion website. 

- **Update Firmware**
  - Updates firmware providing you have hardwar that supports it.
- **Speed up DNF**
  - Enables fastest mirror
  - Sets max parallel downloads to 10
  - Enables DeltaRPMs
- **Enable Flatpak**
  - Adds the flatpak repo and updates
- **Install Software**
  - Installs the following pieces of software
    1. google-chrome-stable 
    2. lolcat 
    3. figlet 
    4. neofetch 
    5. steam 
    6. terminology 
    7. btop 
    8. discord 
    9. gnome-extensions-app 
    10. gnome-tweaks 
    11. vlc 
    12. neofetch 
    13. cmatrix 
    14. p7zip 
    15. unzip 
    16. gparted 
    17. nikto 
    18. nmap 
    19. blender 
    20. gimp 
    21. digikam 
    22. kdenlive 
    23. transmission 
    24. flameshot 
    25. persepolis 
    26. libreoffice 
    27. deja-dup
- **Install Oh-My-ZSH**
  - Installs Oh-My-Zsh - https://ohmyz.sh/
- **Install Starship Prompt**
  - Installs the Starship prompt for ZSH - https://starship.rs/
- **Install Extras**
  - Installs the following theme
    1. gnome-shell-theme-flat-remix
    2. flat-remix-theme
    3. flat-remix-icon-theme
  - Along with the following fonts
    1. iosevka-term-fonts
    2. jetbrains-mono-fonts-all
    3. terminus-fonts
    4. terminus-fonts-console
    5. google-noto-fonts-common
    6. mscore-fonts-all
    7. fira-code-fonts
    8. better fonts by dawid
  - Installs the following extras
    1. Sound and video group
    2. libdvdcss
    3. gstreamer plugins
- **Install Nvidia**
  - Installs the akmod-nvidia driver from the RPMFusion repo's