# Dotfiles

Personal dotfiles and package lists for Ubuntu/GNOME setup.

## Contents

### Configs
- `.zshrc` - Zsh configuration with Oh My Zsh, aliases, and path setup

### Package Lists
- `apt-packages.txt` - APT packages (dev tools, PHP, databases, system utilities)
- `snap-packages.txt` - Snap packages (Firefox, Steam, etc.)
- `flatpak-packages.txt` - Flatpak applications
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
- Install global pnpm packages
- Install global Composer packages
- Symlink .zshrc to home directory

### Manual Installation

Some tools require manual installation. See [MANUAL.md](MANUAL.md) for instructions.

## Requirements

- Ubuntu 24.04+
- sudo access
