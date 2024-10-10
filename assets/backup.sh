#!/bin/bash

# Files to back up
FILES_TO_BACKUP=(
    "/etc/fstab"
    "$HOME/.bashrc"
    "$HOME/.zshrc"
    "$HOME/.config/kitty"
)

# Function to set backup location
set_backup_location() {
    read -p "Enter the backup directory path: " BACKUP_DIR
    mkdir -p "$BACKUP_DIR"
    echo "Backup directory set to: $BACKUP_DIR"
}

# Backup function
backup_files() {
    DATE=$(date +"%Y%m%d_%H%M")

    for FILE in "${FILES_TO_BACKUP[@]}"; do
        if [ -d "$FILE" ]; then
            # If it's a directory, create a tar.gz archive
            TAR_FILE="$BACKUP_DIR/$(basename "$FILE")_$DATE.tar.gz"
            tar -czf "$TAR_FILE" -C "$(dirname "$FILE")" "$(basename "$FILE")"
            echo "Backed up directory: $FILE to $TAR_FILE"
        elif [ -f "$FILE" ]; then
            # If it's a file, copy it directly
            cp "$FILE" "$BACKUP_DIR/$(basename "$FILE")_$DATE.bak"
            echo "Backed up file: $FILE to $BACKUP_DIR"
        else
            echo "File/Directory not found: $FILE"
        fi
    done
}

# Set the backup location
set_backup_location

# Menu
while true; do
    echo "Menu:"
    echo "1. Backup files"
    echo "2. Change backup location"
    echo "3. Exit"
    read -p "Choose an option [1-3]: " OPTION

    case $OPTION in
        1)
            backup_files
            ;;
        2)
            set_backup_location
            ;;
        3)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose again."
            ;;
    esac
    echo ""
done
