#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
theme_source="$script_dir/everforest-sway"
wallpaper_source="$script_dir/../wallpapers/everforest/fog_forest_1.png"
theme_target="/usr/share/sddm/themes/everforest-sway"
config_target="/etc/sddm.conf.d/90-everforest-theme.conf"

if ! command -v sddm-greeter-qt6 >/dev/null 2>&1; then
    echo "sddm-greeter-qt6 is required; install Fedora's sddm package first." >&2
    exit 1
fi

sudo install -d -m 0755 "$theme_target" /etc/sddm.conf.d
sudo install -m 0644 \
    "$theme_source/Main.qml" \
    "$theme_source/metadata.desktop" \
    "$theme_target/"
sudo install -m 0644 "$theme_source/theme-installed.conf" "$theme_target/theme.conf"
sudo install -m 0644 "$wallpaper_source" "$theme_target/background.png"
sudo install -m 0644 "$script_dir/90-everforest-theme.conf" "$config_target"

echo "Installed the Everforest SDDM theme. It will be used at the next login."
echo "Preview source with: sddm-greeter-qt6 --test-mode --theme $theme_source"
