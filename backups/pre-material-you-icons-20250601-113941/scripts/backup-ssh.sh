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

# Create backup directory
BACKUP_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")/private"
mkdir -p "$BACKUP_DIR"

# Backup SSH keys
print_message "Backing up SSH keys..."
if [ -f ~/.ssh/id_ed25519 ] && [ -f ~/.ssh/id_ed25519.pub ]; then
    # Create a tar archive of the SSH keys
    tar -czf /tmp/ssh_backup.tar.gz -C ~/.ssh id_ed25519 id_ed25519.pub
    
    print_message "Enter a strong password to encrypt your SSH keys..."
    # Encrypt the archive with interactive password prompt
    if gpg --symmetric --cipher-algo AES256 --output "$BACKUP_DIR/ssh_keys.tar.gz.gpg" /tmp/ssh_backup.tar.gz; then
        # Clean up only if encryption was successful
        rm /tmp/ssh_backup.tar.gz
        print_success "SSH keys backed up to $BACKUP_DIR/ssh_keys.tar.gz.gpg"
        print_message "Remember your encryption password!"
    else
        rm /tmp/ssh_backup.tar.gz
        print_error "Failed to encrypt SSH keys"
    fi
else
    print_error "SSH keys not found in ~/.ssh/"
fi 