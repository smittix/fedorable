#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Step 1: Add Microsoft Edge repository
echo "Adding Microsoft Edge repository..."

EDGE_REPO="/etc/yum.repos.d/microsoft-edge.repo"
if [ ! -f "$EDGE_REPO" ]; then
    cat <<EOF | tee $EDGE_REPO
[microsoft-edge]
name=Microsoft Edge
baseurl=https://packages.microsoft.com/yumrepos/edge
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
else
    echo "Microsoft Edge repository already exists."
fi

# Step 2: Install Microsoft Edge
echo "Installing Microsoft Edge (Stable)..."

# Update the package list and install Edge
dnf check-update
dnf install microsoft-edge-stable -y

# Step 3: Confirm installation
if command -v microsoft-edge > /dev/null; then
    echo "Microsoft Edge has been successfully installed!"
else
    echo "Failed to install Microsoft Edge."
fi
