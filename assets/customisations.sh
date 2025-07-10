#!/bin/bash

# Ensure required environment vars are set
: "${ACTUAL_USER:?ACTUAL_USER is not set}"
: "${DBUS_SESSION_BUS_ADDRESS:?DBUS_SESSION_BUS_ADDRESS is not set}"

set_gsetting() {
    local schema="$1"
    local key="$2"
    local value="$3"
    sudo -u "$ACTUAL_USER" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
        gsettings set "$schema" "$key" "$value" || echo "⚠️ Failed to set $schema $key"
}

setup_fonts() {
    set_gsetting org.gnome.desktop.interface document-font-name 'Noto Sans Regular 10'
    set_gsetting org.gnome.desktop.interface font-name 'Noto Sans Regular 10'
    set_gsetting org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10'
    set_gsetting org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans Regular 10'
    dialog --msgbox "Custom fonts have been set." 10 50
}

customize_clock() {
    set_gsetting org.gnome.desktop.interface clock-format '24h'
    set_gsetting org.gnome.desktop.interface clock-show-date true
    set_gsetting org.gnome.desktop.interface clock-show-seconds false
    set_gsetting org.gnome.desktop.interface clock-show-weekday false
    dialog --msgbox "Clock has been customized." 10 50
}

enable_window_buttons() {
    set_gsetting org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"
    dialog --msgbox "Window buttons enabled." 10 50
}

center_windows() {
    set_gsetting org.gnome.mutter center-new-windows true
    dialog --msgbox "Windows will now be centered." 10 50
}

disable_auto_maximize() {
    set_gsetting org.gnome.mutter auto-maximize false
    dialog --msgbox "Auto-maximize disabled." 10 50
}

perform_all() {
    setup_fonts
    customize_clock
    enable_window_buttons
    center_windows
    disable_auto_maximize
}
