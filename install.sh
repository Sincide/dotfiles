#!/bin/bash

LOGFILE="$HOME/install.log"
SCRIPTDIR="$(dirname "$(realpath "$0")")/scripts"
BOLD="\e[1m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# Clean log file
: > "$LOGFILE"

log() {
    echo -e "${BLUE}[*]${RESET} $1" | tee -a "$LOGFILE"
}

log_success() {
    echo -e "${GREEN}[✓]${RESET} $1" | tee -a "$LOGFILE"
}

log_warning() {
    echo -e "${YELLOW}[!]${RESET} $1" | tee -a "$LOGFILE"
}

log_error() {
    echo -e "${RED}[✗]${RESET} $1" | tee -a "$LOGFILE" >&2
}

run_script() {
    local script="$1"
    log "Running ${BOLD}$script${RESET}..."
    if bash "$SCRIPTDIR/$script"; then
        log_success "$script completed successfully."
    else
        log_error "$script failed."
        while true; do
            echo -ne "${YELLOW}>>${RESET} Do you want to continue? [y/N]: "
            read -r response
            case "$response" in
                [yY]) break ;;
                [nN]|"") log "Installation aborted by user."; exit 1 ;;
                *) log_warning "Please answer y or n." ;;
            esac
        done
    fi
}

log "🚀 Starting Arch Linux post-install script..."
log "📝 Logging to: ${LOGFILE}"
echo ""

run_script "01-packages.sh"
run_script "02-shell.sh"
run_script "03-dotfiles.sh"
run_script "04-hyprland.sh"
run_script "05-overdrive.sh"

echo ""
log_success "✅ All steps completed."
log "🎉 You can now start customizing your system."
