#!/bin/bash

# Array of extensions with UUIDs and URLs
EXTENSIONS=(
    "dash-to-dock@micxgx.gmail.com https://github.com/micheleg/dash-to-dock/releases/download/extensions.gnome.org-v92/dash-to-dock@micxgx.gmail.com.zip"
    # Add more extensions here
)

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# Loop through each extension
for EXTENSION in "${EXTENSIONS[@]}"; do
    # Extract UUID and URL from the current extension entry
    EXTENSION_UUID=$(echo $EXTENSION | awk '{print $1}')
    EXTENSION_URL=$(echo $EXTENSION | awk '{print $2}')
    
    echo "Installing extension $EXTENSION_UUID from $EXTENSION_URL"
    
    # Download the extension zip file
    wget $EXTENSION_URL -O extension.zip
    
    # Extract the extension
    unzip extension.zip -d $EXTENSION_UUID
    
    # Move the extension to the GNOME extensions directory
    mv $EXTENSION_UUID ~/.local/share/gnome-shell/extensions/
    
    # Enable the extension
    gnome-extensions enable $EXTENSION_UUID
done

# Clean up temporary directory
cd ~
rm -rf $TEMP_DIR

# Restart GNOME Shell (optional, usually needed to apply changes)
notify-send -t 5000 "Extension Installed" "Please logout and log back in again for the changes to take effect"
