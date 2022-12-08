# View current settings - gsettings list-recursively org.gnome.desktop.interface
#Font Settings
gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans 11'
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 12'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans 11'

# Other Settings
gsettings set org.gnome.desktop.interface clock-format '24h'
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface clock-show-seconds false
gsettings set org.gnome.desktop.interface clock-show-weekday false
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface cursor-size 24
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
gsettings set org.gnome.desktop.interface font-rgba-order 'rgb'
gsettings set org.gnome.desktop.interface gtk-color-palette 'black:white:gray50:red:purple:blue:light blue:green:yellow:orange:lavender:brown:goldenrod4:dodger blue:pink:light green:gray10:gray30:gray75:gray90'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Flat-Remix-Blue-Dark'

# Enable window buttons
gsettings set org.gnome.desktop.wm.preferences button-layout ":close,minimize,maximize"

# Set new windows centered
gsettings set org.gnome.mutter center-new-windows true

