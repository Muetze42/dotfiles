#!/bin/bash

OUTPUT_DIR="./packages"
mkdir -p "$OUTPUT_DIR"
JETBRAINS_PLUGIN_DIR="$OUTPUT_DIR/jetbrains-plugins"
mkdir -p "$JETBRAINS_PLUGIN_DIR"
TAB="$(printf '\t')"

version_greater() {
  [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" == "$1" && "$1" != "$2" ]]
}

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

# JetBrains plugins for the latest installed version of each IDE
find "$OUTPUT_DIR" -maxdepth 1 -type f -name 'jetbrains-plugins-*.txt' -delete
find "$JETBRAINS_PLUGIN_DIR" -maxdepth 1 -type f -name '*.txt' -delete

if [ -d "$HOME/.local/share/JetBrains" ]; then
  declare -A jetbrains_latest_versions
  declare -A jetbrains_latest_dirs

  while IFS= read -r ide_dir; do
    ide_name="$(basename "$ide_dir")"

    if [[ "$ide_name" =~ ^([A-Za-z]+)([0-9]{4}\.[0-9]+)$ ]]; then
      product="${BASH_REMATCH[1]}"
      version="${BASH_REMATCH[2]}"

      if [ -z "${jetbrains_latest_versions[$product]}" ] || version_greater "$version" "${jetbrains_latest_versions[$product]}"; then
        jetbrains_latest_versions[$product]="$version"
        jetbrains_latest_dirs[$product]="$ide_dir"
      fi
    fi
  done < <(find "$HOME/.local/share/JetBrains" -maxdepth 1 -mindepth 1 -type d ! -name 'Toolbox' | sort)

  printf '%s\n' "${!jetbrains_latest_dirs[@]}" | sort | while IFS= read -r product; do
    ide_dir="${jetbrains_latest_dirs[$product]}"
    output_file="$JETBRAINS_PLUGIN_DIR/${product}.txt"

    find "$ide_dir" -maxdepth 1 -mindepth 1 \
      \( -type d -o \( -type f -name '*.jar' \) \) ! -name '.*' 2>/dev/null |
      while IFS= read -r plugin_path; do
        plugin_name="$(basename "$plugin_path")"
        printf '%s\n' "${plugin_name%.jar}"
      done | sed '/^$/d' | sort -u > "$output_file"
  done
fi

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
LOCAL_BIN_DIR="$OUTPUT_DIR/.local-bin"
mkdir -p "$LOCAL_BIN_DIR"

# ZSHRC config
cp ~/.zshrc "$OUTPUT_DIR/.zshrc"

# User scripts
find "$LOCAL_BIN_DIR" -mindepth 1 -maxdepth 1 -type f -delete 2>/dev/null
find "$HOME/.local/bin" -maxdepth 1 -type f 2>/dev/null |
  while IFS= read -r script_file; do
    if head -n1 "$script_file" 2>/dev/null | grep -q '^#!'; then
      cp "$script_file" "$LOCAL_BIN_DIR/"
    fi
  done

# Sanitize secret exports in the collected shell config.
# Keep the variable names, but clear their values in the exported file.
sed -i -E \
  's#^([[:space:]]*export[[:space:]]+([A-Z0-9_]*(API_KEY|TOKEN|SECRET))[[:space:]]*=).*#\1""#' \
  "$OUTPUT_DIR/.zshrc"

echo "Done. Check $OUTPUT_DIR"
