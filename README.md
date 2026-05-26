# Dotfiles

Personal dotfiles and package lists for Ubuntu/GNOME setup.

## Contents

### Configs
- `.zshrc` - Zsh configuration with Oh My Zsh, aliases, and path setup
- `.local-bin/` - Personal scripts from `~/.local/bin`

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

### Automated Installation

```bash
./install.sh
```

This will:
- Install APT packages
- Install Snap packages
- Install PHP extensions
- Install GNOME extensions
- Show exported AppImage inventory
- Show exported JetBrains Toolbox app inventory
- Show exported JetBrains plugin inventories for the latest IDE versions
- Show exported manual `/opt` app inventory
- Install global pnpm packages
- Install global Composer packages
- Symlink .zshrc to home directory
- Copy personal `~/.local/bin` scripts

### Manual Installation

Some tools require manual installation. See [MANUAL.md](MANUAL.md) for instructions.

## Requirements

- Ubuntu 26.04 or later
- sudo access
