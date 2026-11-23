#!/usr/bin/env bash
set -euo pipefail

PLASMOID_ID="org.d3signa.vscodiumprofiles"
OLD_PLASMOID_ID="org.ftristan.vscodiumprofiles"

printf 'Removing the VSCodium profile picker installation.\n'

if command -v kpackagetool6 >/dev/null 2>&1; then
    if kpackagetool6 --type Plasma/Applet --show "$PLASMOID_ID" >/dev/null 2>&1; then
        printf 'Removing plasmoid %s\n' "$PLASMOID_ID"
        kpackagetool6 --type Plasma/Applet --remove "$PLASMOID_ID"
    else
        printf 'Plasmoid %s is not installed; skipping.\n' "$PLASMOID_ID"
    fi
else
    printf 'kpackagetool6 not found; skipping plasmoid removal.\n' >&2
fi

helper_target="$HOME/.local/bin/vscodium-profile.sh"
desktop_target="$HOME/.local/share/applications/vscodium-profile.desktop"

for target in "$helper_target" "$desktop_target"; do
    if [[ -e "$target" || -L "$target" ]]; then
        printf 'Removing %s\n' "$target"
        rm -f "$target"
    else
        printf 'Not found; skipping: %s\n' "$target"
    fi
done

if command -v update-desktop-database >/dev/null 2>&1 &&
   [[ -d "$HOME/.local/share/applications" ]]; then
    update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

if command -v kpackagetool6 >/dev/null 2>&1 &&
   kpackagetool6 --type Plasma/Applet --show "$OLD_PLASMOID_ID" >/dev/null 2>&1; then
    printf 'Note: old plasmoid %s is still installed; remove it manually if needed.\n' \
        "$OLD_PLASMOID_ID" >&2
fi

printf '\nUninstall complete.\n'
printf 'Restart Plasma or log out and back in if the widget is still visible.\n'
