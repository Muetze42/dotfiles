#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

confirm() {
    read -p "$1 [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# APT packages
install_apt() {
    info "Installing APT packages..."
    if [[ -f "$SCRIPT_DIR/packages/apt-packages.txt" ]]; then
        sudo apt update
        xargs -a "$SCRIPT_DIR/packages/apt-packages.txt" sudo apt install -y
        success "APT packages installed"
    else
        warn "apt-packages.txt not found"
    fi
}

# Snap packages
install_snap() {
    info "Installing Snap packages..."
    if [[ -f "$SCRIPT_DIR/packages/snap-packages.txt" ]]; then
        while IFS= read -r package || [[ -n "$package" ]]; do
            [[ -z "$package" ]] && continue
            info "Installing snap: $package"
            sudo snap install "$package" 2>/dev/null || sudo snap install "$package" --classic 2>/dev/null || warn "Failed to install $package"
        done < "$SCRIPT_DIR/packages/snap-packages.txt"
        success "Snap packages installed"
    else
        warn "snap-packages.txt not found"
    fi
}

# PHP extensions (reference only - actual packages installed via APT)
check_php() {
    info "Checking PHP modules..."
    if command -v php &> /dev/null; then
        php -m
        success "PHP modules listed above"
    else
        warn "PHP not installed"
    fi
}

# GNOME extensions
install_gnome_extensions() {
    info "GNOME extensions need manual installation via Extensions app"
    info "Extensions list: $SCRIPT_DIR/packages/gnome-extensions.txt"
    if command -v gnome-extensions &> /dev/null; then
        info "Installed extensions:"
        gnome-extensions list
    fi
}

# pnpm global packages
install_pnpm_global() {
    info "Installing global pnpm packages..."
    if ! command -v pnpm &> /dev/null; then
        if command -v npm &> /dev/null; then
            npm install -g pnpm
        else
            warn "npm/pnpm not found. Install nvm first (see MANUAL.md)"
            return
        fi
    fi
    if [[ -f "$SCRIPT_DIR/packages/pnpm-global.txt" ]]; then
        xargs -a "$SCRIPT_DIR/packages/pnpm-global.txt" pnpm add -g
        success "pnpm global packages installed"
    else
        warn "pnpm-global.txt not found"
    fi
}

# Composer global packages
install_composer_global() {
    info "Installing global Composer packages..."
    if ! command -v composer &> /dev/null; then
        warn "Composer not found"
        return
    fi
    if [[ -f "$SCRIPT_DIR/packages/composer-global.json" ]]; then
        mkdir -p ~/.config/composer
        cp "$SCRIPT_DIR/packages/composer-global.json" ~/.config/composer/composer.json
        composer global install
        success "Composer global packages installed"
    else
        warn "composer-global.json not found"
    fi
}

# Symlink configs
symlink_configs() {
    info "Symlinking config files..."

    if [[ -f "$SCRIPT_DIR/configs/.zshrc" ]]; then
        if [[ -f ~/.zshrc ]] && [[ ! -L ~/.zshrc ]]; then
            if confirm "~/.zshrc exists. Backup and replace?"; then
                mv ~/.zshrc ~/.zshrc.backup
                info "Backed up to ~/.zshrc.backup"
            else
                warn "Skipping .zshrc"
                return
            fi
        fi
        ln -sf "$SCRIPT_DIR/configs/.zshrc" ~/.zshrc
        success "Linked .zshrc"
    fi
}

# Main
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Dotfiles Installer${NC}"
    echo -e "${BLUE}================================${NC}"
    echo

    if confirm "Install APT packages?"; then
        install_apt
    fi

    if confirm "Install Snap packages?"; then
        install_snap
    fi

    if confirm "Check PHP modules?"; then
        check_php
    fi

    if confirm "Show GNOME extensions info?"; then
        install_gnome_extensions
    fi

    if confirm "Install global pnpm packages?"; then
        install_pnpm_global
    fi

    if confirm "Install global Composer packages?"; then
        install_composer_global
    fi

    if confirm "Symlink config files?"; then
        symlink_configs
    fi

    echo
    success "Done! See MANUAL.md for additional setup steps."
}

main "$@"
