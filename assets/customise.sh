#!/bin/bash

# Function to set the hostname
set_hostname() {
    hostname=$(dialog --inputbox "Enter new hostname:" 10 50 3>&1 1>&2 2>&3 3>&-)
    if [ ! -z "$hostname" ]; then
        sudo hostnamectl set-hostname "$hostname"
        dialog --msgbox "Hostname set to $hostname" 10 50
    else
        dialog --msgbox "Hostname not set. Input was empty." 10 50
    fi
}

# Function to setup custom fonts
setup_fonts() {
    gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans Regular 10'
    gsettings set org.gnome.desktop.interface font-name 'Noto Sans Regular 10'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10'
    gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans Regular 10'
    dialog --msgbox "Custom fonts have been set." 10 50
}

# Function to customize the clock
customize_clock() {
    gsettings set org.gnome.desktop.interface clock-format '24h'
    gsettings set org.gnome.desktop.interface clock-show-date true
    gsettings set org.gnome.desktop.interface clock-show-seconds false
    gsettings set org.gnome.desktop.interface clock-show-weekday false
    dialog --msgbox "Clock has been customized." 10 50
}

# Function to enable window buttons
enable_window_buttons() {
    gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"
    dialog --msgbox "Window buttons (minimize, maximize, close) have been enabled." 10 50
}

# Function to center windows
center_windows() {
    gsettings set org.gnome.mutter center-new-windows true
    dialog --msgbox "Windows will now be centered." 10 50
}

# Function to disable auto-maximize
disable_auto_maximize() {
    gsettings set org.gnome.mutter auto-maximize false
    dialog --msgbox "Auto-maximize has been disabled." 10 50
}

# Function to perform all tasks
perform_all() {
    setup_fonts
    customize_clock
    enable_window_buttons
    center_windows
    disable_auto_maximize
}

# Main menu
while true; do
    CHOICE=$(dialog --clear --backtitle "Fedora System Configuration" \
        --title "Main Menu" \
        --menu "Choose an option:" 15 50 6 \
        1 "Set Hostname" \
        2 "Setup Custom Fonts" \
        3 "Customize Clock" \
        4 "Enable Window Buttons" \
        5 "Center Windows" \
        6 "Disable Auto-Maximize" \
        7 "Perform All Tasks" \
        8 "Exit" \
        3>&1 1>&2 2>&3)
    
    case $CHOICE in
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

clear
