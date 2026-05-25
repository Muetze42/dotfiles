#!/bin/bash

OUTPUT_DIR="./packages"
mkdir -p "$OUTPUT_DIR"
TAB="$(printf '\t')"

# PHP Extensions
php -m | grep -v '^\[' | grep -v '^$' | sort -u > "$OUTPUT_DIR/php-extensions.txt"

# APT Packages (manuell installiert)
apt-mark showmanual | sort > "$OUTPUT_DIR/apt-packages.txt"

# Gnome Extensions
gnome-extensions list --enabled | sort > "$OUTPUT_DIR/gnome-extensions.txt" 2>/dev/null

# Snap packages
snap list | tail -n +2 | awk '{print $1}' | sort > "$OUTPUT_DIR/snap-packages.txt"

# Flatpak
flatpak list --app --columns=application | sort > "$OUTPUT_DIR/flatpak-packages.txt" 2>/dev/null

# JetBrains Toolbox apps
find \
  "$HOME/.local/share/applications" \
  -maxdepth 1 -type f -name 'jetbrains*.desktop' 2>/dev/null |
  while IFS= read -r desktop_file; do
    grep -E '^Exec=' "$desktop_file" |
      sed -nE 's#.*JetBrains/Toolbox/apps/([^/]+)/bin/.*#\1#p'
  done | sed '/^$/d' | sort -u > "$OUTPUT_DIR/jetbrains-toolbox-apps.txt"

# Manually installed desktop apps under /opt
find \
  "$HOME/.local/share/applications" \
  /usr/share/applications \
  -maxdepth 1 -type f -name '*.desktop' 2>/dev/null |
  while IFS= read -r desktop_file; do
    app_name="$(sed -n 's/^Name=//p' "$desktop_file" | head -n1)"
    exec_path="$(grep -E '^Exec=' "$desktop_file" |
      grep -oE '(/opt/[^[:space:]"]+)' |
      grep -vE '^/opt/google/chrome/' |
      grep -vE '^/opt/jetbrains/' |
      head -n1)"

    if [ -n "$app_name" ] && [ -n "$exec_path" ]; then
      printf '%s\t%s\n' "$exec_path" "$app_name"
    fi
  done | sort -t "$TAB" -k1,1 -k2,2 | awk -F '\t' '!seen[$1]++ { print $2 }' > "$OUTPUT_DIR/manual-opt-apps.txt"

# AppImages registered via desktop files or stored in common AppImage directories
{
  find \
    "$HOME/.local/share/applications" \
    "$HOME/.local/share/appimagekit" \
    -maxdepth 1 -type f -name '*.desktop' 2>/dev/null |
    while IFS= read -r desktop_file; do
      grep -E '^Exec=' "$desktop_file" |
        grep -oE '(/[^[:space:]"]+\.[Aa][Pp][Pp][Ii][Mm][Aa][Gg][Ee])' |
        sed 's#.*/##'
    done

  find \
    "$HOME/AppImages" \
    "$HOME/Applications" \
    "$HOME/.local/bin" \
    -maxdepth 2 -type f \( -iname '*.appimage' -o -iname '*.AppImage' \) -printf '%f\n' 2>/dev/null
} | sed '/^$/d' | sort -u > "$OUTPUT_DIR/appimage-packages.txt"

# Global (p)npm packages
npm list -g --depth=0 --parseable | tail -n +2 | xargs -n1 basename | sort > "$OUTPUT_DIR/pnpm-global.txt" 2>/dev/null

# Composer global packages
cp ~/.config/composer/composer.json "$OUTPUT_DIR/composer-global.json" 2>/dev/null

OUTPUT_DIR="./configs"
mkdir -p "$OUTPUT_DIR"

# ZSHRC config
cp ~/.zshrc "$OUTPUT_DIR/.zshrc"

# Sanitize secret exports in the collected shell config.
# Keep the variable names, but clear their values in the exported file.
sed -i -E \
  's#^([[:space:]]*export[[:space:]]+([A-Z0-9_]*(API_KEY|TOKEN|SECRET))[[:space:]]*=).*#\1""#' \
  "$OUTPUT_DIR/.zshrc"

echo "Done. Check $OUTPUT_DIR"
