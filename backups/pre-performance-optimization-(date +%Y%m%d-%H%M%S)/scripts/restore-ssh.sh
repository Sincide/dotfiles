#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print colored message
print_message() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
    exit 1
}

# Check if gpg is installed
if ! command -v gpg &> /dev/null; then
    print_error "GPG is not installed. Please install it first."
fi

# Find backup file
BACKUP_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")/private"
BACKUP_FILE="$BACKUP_DIR/ssh_keys.tar.gz.gpg"

if [ ! -f "$BACKUP_FILE" ]; then
    print_error "Backup file not found at $BACKUP_FILE"
fi

# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Restore SSH keys
print_message "Restoring SSH keys..."
print_message "Enter the password you used to encrypt your SSH keys..."

# Decrypt and extract
if gpg --no-use-agent --pinentry-mode loopback --decrypt --output /tmp/ssh_backup.tar.gz "$BACKUP_FILE"; then
    if tar -xzf /tmp/ssh_backup.tar.gz -C ~/.ssh; then
        # Clean up
        rm /tmp/ssh_backup.tar.gz
        
        # Set correct permissions
        chmod 600 ~/.ssh/id_ed25519
        chmod 644 ~/.ssh/id_ed25519.pub
        
        print_success "SSH keys restored to ~/.ssh/"
        print_message "Test your SSH connection with: ssh -T git@gitlab.com"
    else
        rm /tmp/ssh_backup.tar.gz
        print_error "Failed to extract SSH keys"
    fi
else
    rm -f /tmp/ssh_backup.tar.gz
    print_error "Failed to decrypt SSH keys. Wrong password?"
fi 