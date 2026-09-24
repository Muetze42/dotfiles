# Dotfiles

Personal dotfiles and package lists for Ubuntu/GNOME setup.

## Contents

### Configs
- `.zshrc` - Zsh configuration with Oh My Zsh, aliases, and path setup
- `.local-bin/` - Personal scripts from `~/.local/bin`
- `.cpx/aliases.json` - CPX package aliases

### Valet

- `valet/` - Saved Valet DNS fixes and VPN domain configuration with [restore instructions](valet/README.md)

### Package Lists
- `apt-packages.txt` - APT packages (dev tools, PHP, databases, system utilities)
- `snap-packages.txt` - Snap packages (Firefox, Steam, etc.)
- `flatpak-packages.txt` - Flatpak applications
- `jetbrains-toolbox-apps.txt` - JetBrains IDEs/apps installed via JetBrains Toolbox
- `jetbrains-plugins/` - Installed plugins for the latest locally installed version of each JetBrains IDE, one alphabetically named file per IDE
- `manual-opt-apps.txt` - Desktop apps registered from manual installs under `/opt`
- `appimage-packages.txt` - Registered AppImages and AppImages in common local install directories
- `php-extensions.txt` - PHP modules reference
- `gnome-extensions.txt` - GNOME Shell extensions
- `pnpm-global.txt` - Global pnpm packages
- `composer-global.json` - Global Composer packages

## Usage

The package lists are inventories of the current setup and can be used as a
reference when restoring the system. Configurations and applications must be
installed or copied manually.

### Installation

See [MANUAL.md](MANUAL.md) for the manual installation steps.

## Requirements

- Ubuntu 26.04 or later
- sudo access
