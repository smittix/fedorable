#!/bin/bash

# Variables
GHIDRA_URL="https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest"
INSTALL_DIR="/opt/ghidra"
DOWNLOAD_DIR="/tmp"
GHIDRA_ZIP="ghidra.zip"

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Step 1: Download the latest release of Ghidra
echo "Fetching the latest Ghidra release information..."
GHIDRA_DOWNLOAD_URL=$(curl -s $GHIDRA_URL | grep "browser_download_url.*zip" | cut -d '"' -f 4)

if [[ -z "$GHIDRA_DOWNLOAD_URL" ]]; then
    echo "Failed to fetch Ghidra download URL. Exiting."
    exit 1
fi

echo "Latest Ghidra release found: $GHIDRA_DOWNLOAD_URL"
echo "Downloading Ghidra..."
curl -L -o "$DOWNLOAD_DIR/$GHIDRA_ZIP" "$GHIDRA_DOWNLOAD_URL"

# Step 2: Extract the Ghidra archive
echo "Extracting Ghidra to $INSTALL_DIR..."
mkdir -p $INSTALL_DIR
unzip -q "$DOWNLOAD_DIR/$GHIDRA_ZIP" -d "$INSTALL_DIR"

# Find the extracted folder (assuming it's the only folder in the target directory)
GHIDRA_FOLDER=$(find $INSTALL_DIR -mindepth 1 -maxdepth 1 -type d)

# Step 3: Create a symlink to make Ghidra accessible system-wide
echo "Creating symlink for Ghidra..."
ln -sf "$GHIDRA_FOLDER/ghidraRun" /usr/local/bin/ghidra

# Step 4: Clean up downloaded files
echo "Cleaning up..."
rm -f "$DOWNLOAD_DIR/$GHIDRA_ZIP"

# Step 5: Display success message
echo "Ghidra installation complete! You can run Ghidra using the 'ghidra' command."
