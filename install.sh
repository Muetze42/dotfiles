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

# AppImages
show_appimages() {
    info "AppImages are exported as a reference list and need manual restore"
    info "AppImage list: $SCRIPT_DIR/packages/appimage-packages.txt"
}

# JetBrains Toolbox apps
show_jetbrains_toolbox_apps() {
    info "JetBrains Toolbox apps are exported as a reference list and need restore via Toolbox"
    info "JetBrains Toolbox app list: $SCRIPT_DIR/packages/jetbrains-toolbox-apps.txt"
}

# JetBrains plugins
show_jetbrains_plugins() {
    info "JetBrains plugins are exported as reference lists for the latest installed IDE version"
    find "$SCRIPT_DIR/packages/jetbrains-plugins" -maxdepth 1 -type f -name '*.txt' | sort |
        while IFS= read -r plugin_file; do
            info "JetBrains plugin list: $plugin_file"
        done
}

# Manually installed desktop apps under /opt
show_manual_opt_apps() {
    info "Apps installed under /opt are exported as a reference list and need manual restore"
    info "Manual /opt app list: $SCRIPT_DIR/packages/manual-opt-apps.txt"
}

# pnpm global packages
install_pnpm_global() {
    info "Installing global pnpm packages..."
    if ! command -v pnpm &> /dev/null; then
        warn "npm/pnpm not found. Install nvm first (see MANUAL.md)"
        return
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

    if [[ -d "$SCRIPT_DIR/configs/.local-bin" ]]; then
        mkdir -p ~/.local/bin
        find "$SCRIPT_DIR/configs/.local-bin" -maxdepth 1 -type f | while IFS= read -r script_file; do
            target="$HOME/.local/bin/$(basename "$script_file")"
            cp "$script_file" "$target"
            chmod +x "$target"
        done
        success "Copied ~/.local/bin scripts"
    fi

    if [[ -f "$SCRIPT_DIR/configs/.cpx/aliases.json" ]]; then
        mkdir -p ~/.cpx
        if [[ -f ~/.cpx/aliases.json ]] && [[ ! -L ~/.cpx/aliases.json ]]; then
            if confirm "~/.cpx/aliases.json exists. Backup and replace?"; then
                mv ~/.cpx/aliases.json ~/.cpx/aliases.json.backup
                info "Backed up to ~/.cpx/aliases.json.backup"
            else
                warn "Skipping CPX aliases"
                return
            fi
        fi
        cp "$SCRIPT_DIR/configs/.cpx/aliases.json" ~/.cpx/aliases.json
        success "Copied CPX aliases"
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

    if confirm "Show AppImage info?"; then
        show_appimages
    fi

    if confirm "Show JetBrains Toolbox app info?"; then
        show_jetbrains_toolbox_apps
    fi

    if confirm "Show JetBrains plugin info?"; then
        show_jetbrains_plugins
    fi

    if confirm "Show manual /opt app info?"; then
        show_manual_opt_apps
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
