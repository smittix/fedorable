# View current settings - gsettings list-recursively org.gnome.desktop.interface
#Font Settings
gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans 10'
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 10'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans 10'

# Other Settings
gsettings set org.gnome.desktop.interface clock-format '24h'
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface clock-show-seconds false
gsettings set org.gnome.desktop.interface clock-show-weekday false

# Enables battery percentage
gsettings set org.gnome.desktop.interface show-battery-percentage true

# Enable window buttons
gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"

# Set new windows centered
gsettings set org.gnome.mutter center-new-windows true

# Fractional Scaling - THIS IS EXPERIMENTAL
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
