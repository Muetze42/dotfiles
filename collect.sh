#!/bin/bash

OUTPUT_DIR="./packages"
mkdir -p "$OUTPUT_DIR"

# PHP Extensions
php -m | sort > "$OUTPUT_DIR/php-extensions.txt"

# APT Packages (manuell installiert)
apt-mark showmanual | sort > "$OUTPUT_DIR/apt-packages.txt"

# Gnome Extensions
gnome-extensions list --enabled | sort > "$OUTPUT_DIR/gnome-extensions.txt" 2>/dev/null

# Snap packages
snap list | tail -n +2 | awk '{print $1}' | sort > "$OUTPUT_DIR/snap-packages.txt"

# Flatpak
flatpak list --app --columns=application | sort > "$OUTPUT_DIR/flatpak-packages.txt" 2>/dev/null

# Global (p)npm packages
npm list -g --depth=0 --parseable | tail -n +2 | xargs -n1 basename | sort > "$OUTPUT_DIR/pnpm-global.txt" 2>/dev/null

# Composer global packages
cp ~/.config/composer/composer.json "$OUTPUT_DIR/composer-global.json" 2>/dev/null

OUTPUT_DIR="./configs"
mkdir -p "$OUTPUT_DIR"

# ZSHRC config
cp ~/.zshrc "$OUTPUT_DIR/.zshrc"

echo "Done. Check $OUTPUT_DIR"