#!/usr/bin/env bash
set -euo pipefail

PLASMOID_ID="org.d3signa.vscodiumprofiles"
OLD_PLASMOID_ID="org.ftristan.vscodiumprofiles"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

die() {
    printf 'install.sh: %s\n' "$*" >&2
    exit 1
}

command -v kpackagetool6 >/dev/null 2>&1 ||
    die "kpackagetool6 is required to install the plasmoid."

package="$SCRIPT_DIR/$PLASMOID_ID.plasmoid"
source_dir="$SCRIPT_DIR/plasmoid/$PLASMOID_ID"

if [[ -f "$package" ]]; then
    package_source="$package"
elif [[ -d "$source_dir" ]]; then
    package_source="$source_dir"
else
    die "plasmoid package not found: expected $package or $source_dir"
fi

[[ -f "$SCRIPT_DIR/vscodium-profile.sh" ]] ||
    die "helper script not found: $SCRIPT_DIR/vscodium-profile.sh"

[[ -f "$SCRIPT_DIR/vscodium-profile.desktop" ]] ||
    die "desktop file not found: $SCRIPT_DIR/vscodium-profile.desktop"

printf 'Installing plasmoid from %s\n' "$package_source"
if kpackagetool6 --type Plasma/Applet --show "$PLASMOID_ID" >/dev/null 2>&1; then
    kpackagetool6 --type Plasma/Applet --upgrade "$package_source"
else
    kpackagetool6 --type Plasma/Applet --install "$package_source"
fi

if kpackagetool6 --type Plasma/Applet --show "$OLD_PLASMOID_ID" >/dev/null 2>&1; then
    printf 'Note: old plasmoid %s is still installed; remove it manually if needed.\n' \
        "$OLD_PLASMOID_ID" >&2
fi

bin_dir="$HOME/.local/bin"
applications_dir="$HOME/.local/share/applications"
helper_target="$bin_dir/vscodium-profile.sh"
desktop_target="$applications_dir/vscodium-profile.desktop"

mkdir -p "$bin_dir" "$applications_dir"

printf 'Installing helper to %s\n' "$helper_target"
install -m 755 "$SCRIPT_DIR/vscodium-profile.sh" "$helper_target"

tmp_desktop="$(mktemp)"
trap 'rm -f "$tmp_desktop"' EXIT
awk -v exec_line="Exec=$helper_target %F" \
    '/^Exec=/ { print exec_line; next } { print }' \
    "$SCRIPT_DIR/vscodium-profile.desktop" > "$tmp_desktop"

printf 'Installing launcher to %s\n' "$desktop_target"
install -m 644 "$tmp_desktop" "$desktop_target"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$applications_dir" >/dev/null 2>&1 || true
fi

printf '\nInstallation complete:\n'
printf '  Plasmoid: %s\n' "$PLASMOID_ID"
printf '  Helper:   %s\n' "$helper_target"
printf '  Launcher: %s\n' "$desktop_target"

if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
    printf '\nNote: %s is not in PATH. The launcher uses the absolute path, so it still works.\n' \
        "$bin_dir" >&2
fi

printf 'Restart Plasma or log out and back in if the plasmoid does not appear immediately.\n'
