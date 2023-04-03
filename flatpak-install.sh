#!/bin/bash

# Check if flatpak is enabled
if ! flatpak --version > /dev/null 2>&1; then
  echo "Error: flatpak is not enabled on this system"
  exit 1
fi

# Read the list of packages from the text file
PACKAGES=$(cat flatpak-packages.txt)

# Install the packages using flatpak
for PACKAGE in $PACKAGES; do
  flatpak install -y $PACKAGE
done
