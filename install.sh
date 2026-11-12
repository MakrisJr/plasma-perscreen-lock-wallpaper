#!/usr/bin/env bash
# Install / update / remove the Per-Screen Image wallpaper plugin for KDE Plasma 6.
#
#   ./install.sh              install, or upgrade if already installed
#   ./install.sh --enable     ...and make it the lock screen wallpaper
#   ./install.sh --uninstall  remove it (and switch the lock screen back to "Image")
#   ./install.sh --package    build dist/<id>-<version>.tar.gz (e.g. for the KDE Store)

set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

PLUGIN_ID="com.github.makrisjr.perscreenimage"
PKG_DIR="package"
TYPE="Plasma/Wallpaper"

need() { command -v "$1" >/dev/null 2>&1 || { echo "error: '$1' not found" >&2; exit 1; }; }

is_installed() {
    kpackagetool6 --type "$TYPE" --show "$PLUGIN_ID" >/dev/null 2>&1
}

install_plugin() {
    need kpackagetool6
    if is_installed; then
        kpackagetool6 --type "$TYPE" --upgrade "$PKG_DIR"
    else
        kpackagetool6 --type "$TYPE" --install "$PKG_DIR"
    fi
}

enable_lockscreen() {
    need kwriteconfig6
    kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin "$PLUGIN_ID"
    echo "Lock screen wallpaper type set to Per-Screen Image."
    echo "Pick images in System Settings → Screen Locking → Appearance → Configure…"
}

uninstall_plugin() {
    need kpackagetool6
    need kreadconfig6
    if [[ "$(kreadconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin)" == "$PLUGIN_ID" ]]; then
        kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.image
        echo "Lock screen wallpaper type switched back to Image."
    fi
    if is_installed; then
        kpackagetool6 --type "$TYPE" --remove "$PLUGIN_ID"
    else
        echo "Plugin is not installed."
    fi
}

build_package() {
    local version
    version=$(sed -n 's/.*"Version": *"\([^"]*\)".*/\1/p' "$PKG_DIR/metadata.json")
    mkdir -p dist
    local out="dist/${PLUGIN_ID}-${version}.tar.gz"
    tar -czf "$out" -C "$PKG_DIR" --transform "s,^\.,${PLUGIN_ID}," .
    echo "Built $out"
}

case "${1:-}" in
    "")            install_plugin ;;
    --enable)      install_plugin; enable_lockscreen ;;
    --uninstall)   uninstall_plugin ;;
    --package)     build_package ;;
    -h|--help)     sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//' ;;
    *)             echo "unknown option: $1 (try --help)" >&2; exit 2 ;;
esac
