#!/bin/bash

OUTPUT_DIR="./packages"
mkdir -p "$OUTPUT_DIR"
JETBRAINS_PLUGIN_DIR="$OUTPUT_DIR/jetbrains-plugins"
mkdir -p "$JETBRAINS_PLUGIN_DIR"
TAB="$(printf '\t')"

read_plugin_xml_value() {
  xml_content="$1"
  tag_name="$2"
  printf '%s\n' "$xml_content" |
    sed -n "s#.*<$tag_name>\\([^<]*\\)</$tag_name>.*#\\1#p" |
    head -n1
}

extract_plugin_metadata() {
  plugin_path="$1"
  plugin_basename="$(basename "$plugin_path")"
  xml_content=""

  if [ -d "$plugin_path" ]; then
    if [ -f "$plugin_path/META-INF/plugin.xml" ]; then
      xml_content="$(tr '\n' ' ' < "$plugin_path/META-INF/plugin.xml" 2>/dev/null)"
    else
      descriptor_jar="$(
        find "$plugin_path" -maxdepth 3 -type f -name '*.jar' 2>/dev/null |
          while IFS= read -r jar_path; do
            if unzip -p "$jar_path" META-INF/plugin.xml >/dev/null 2>&1; then
              printf '%s\n' "$jar_path"
              break
            fi
          done
      )"

      if [ -n "$descriptor_jar" ]; then
        xml_content="$(unzip -p "$descriptor_jar" META-INF/plugin.xml 2>/dev/null | tr '\n' ' ')"
      fi
    fi
  elif [ -f "$plugin_path" ]; then
    xml_content="$(unzip -p "$plugin_path" META-INF/plugin.xml 2>/dev/null | tr '\n' ' ')"
  fi

  plugin_id="$(read_plugin_xml_value "$xml_content" "id")"
  plugin_name="$(read_plugin_xml_value "$xml_content" "name")"
  plugin_version="$(read_plugin_xml_value "$xml_content" "version")"

  if [ -z "$plugin_id" ]; then
    plugin_id="$plugin_name"
  fi

  if [ -z "$plugin_id" ]; then
    plugin_id="${plugin_basename%.jar}"
  fi

  if [ -z "$plugin_name" ]; then
    plugin_name="$plugin_id"
  fi

  printf '%s\t%s\t%s\n' "$plugin_id" "$plugin_version" "$plugin_name"
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
  find "$HOME/.local/share/JetBrains" -maxdepth 1 -mindepth 1 -type d ! -name 'Toolbox' 2>/dev/null |
    while IFS= read -r ide_dir; do
      ide_name="$(basename "$ide_dir")"
      product="$(printf '%s\n' "$ide_name" | sed -nE 's/^([A-Za-z]+)([0-9]{4}\.[0-9]+)$/\1/p')"
      version="$(printf '%s\n' "$ide_name" | sed -nE 's/^([A-Za-z]+)([0-9]{4}\.[0-9]+)$/\2/p')"

      if [ -n "$product" ] && [ -n "$version" ]; then
        printf '%s\t%s\t%s\n' "$product" "$version" "$ide_dir"
      fi
    done |
    sort -t "$TAB" -k1,1 -k2,2Vr |
    awk -F '\t' '!seen[$1]++ { print }' |
    sort -t "$TAB" -k1,1 |
    while IFS="$TAB" read -r product version ide_dir; do
      output_file="$JETBRAINS_PLUGIN_DIR/${product}.txt"
      metadata_file="$(mktemp)"

      find "$ide_dir" -maxdepth 1 -mindepth 1 \
        \( -type d -o \( -type f -name '*.jar' \) \) ! -name '.*' 2>/dev/null |
        while IFS= read -r plugin_path; do
          extract_plugin_metadata "$plugin_path"
        done > "$metadata_file"

      sort -t "$TAB" -k1,1 -k2,2Vr "$metadata_file" |
        awk -F '\t' '!seen[$1]++ {
          if ($3 != "" && $3 != $1) {
            print $3 " (" $1 ")"
          } else {
            print $1
          }
        }' |
        sed '/^$/d' | sort -f > "$output_file"

      rm -f "$metadata_file"
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
CPX_CONFIG_DIR="$OUTPUT_DIR/.cpx"
mkdir -p "$CPX_CONFIG_DIR"

# ZSHRC config
cp ~/.zshrc "$OUTPUT_DIR/.zshrc"

# CPX aliases
if [ -f "$HOME/.cpx/aliases.json" ]; then
  cp "$HOME/.cpx/aliases.json" "$CPX_CONFIG_DIR/aliases.json"
else
  rm -f "$CPX_CONFIG_DIR/aliases.json"
fi

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
