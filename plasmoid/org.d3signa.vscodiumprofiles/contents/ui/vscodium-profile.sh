#!/usr/bin/env bash
# vscodium-profile.sh - choose a VS Code / VSCodium profile, then open it.
# Any file/folder arguments are forwarded to the editor.
#
# Modes (--editor vscodium|vscode may precede any mode; default: vscodium):
#   (no args)             show the GUI picker
#   --list-profiles       print profile names, one per line (for the plasmoid)
#   --last-profile        print the last used profile name (for the plasmoid)
#   --profile NAME [args] launch directly with NAME, forwarding any args

set -euo pipefail

DEFAULT_PROFILE="Default"

die() {
    printf 'vscodium-profile: %s\n' "$*" >&2
    exit 1
}

editor=vscodium
if [[ "${1:-}" == "--editor" ]]; then
    [[ $# -ge 2 ]] || die "--editor requires vscodium or vscode."
    editor=$2
    shift 2
fi

case "$editor" in
    vscodium)
        EDITOR_BIN=codium
        EDITOR_LABEL="VSCodium"
        STORAGE_DIR=VSCodium
        STATE_NAME=vscodium-profile
        ;;
    vscode)
        EDITOR_BIN=code
        EDITOR_LABEL="VS Code"
        STORAGE_DIR=Code
        STATE_NAME=vscode-profile
        ;;
    *)
        die "unknown editor: $editor (use vscodium or vscode)"
        ;;
esac

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/$STATE_NAME"
STATE_FILE="$CONFIG_DIR/last"
STORAGE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/$STORAGE_DIR/User/globalStorage/storage.json"

command -v jq >/dev/null 2>&1 || die "'jq' is required but not found in PATH."

# Build the profile list: Default first, then custom profiles from the editor's storage.
profiles=("$DEFAULT_PROFILE")
if [[ -r "$STORAGE_FILE" ]]; then
    while IFS= read -r name; do
        [[ -n "$name" ]] && profiles+=("$name")
    done < <(jq -r '.userDataProfiles // [] | .[].name // empty' "$STORAGE_FILE" 2>/dev/null)
fi

# Preselect the last used profile, if it still exists.
last=""
if [[ -r "$STATE_FILE" ]]; then
    IFS= read -r last < "$STATE_FILE" || true
fi
preselect="$DEFAULT_PROFILE"
for profile in "${profiles[@]}"; do
    if [[ "$profile" == "$last" ]]; then
        preselect="$profile"
        break
    fi
done

case "${1:-}" in
    --list-profiles)
        printf '%s\n' "${profiles[@]}"
        exit 0
        ;;
    --last-profile)
        printf '%s\n' "$preselect"
        exit 0
        ;;
    --profile)
        [[ $# -ge 2 ]] || die "--profile requires a profile name."
        choice=$2
        known=0
        for profile in "${profiles[@]}"; do
            if [[ "$profile" == "$choice" ]]; then known=1; break; fi
        done
        (( known )) || die "unknown profile: $choice"
        shift 2
        ;;
    *)
        if command -v python3 >/dev/null 2>&1 &&
           python3 -c 'import gi; gi.require_version("Gtk", "3.0"); from gi.repository import Gtk' >/dev/null 2>&1; then
            picker=buttons
        elif command -v kdialog >/dev/null 2>&1; then
            picker=kdialog
        else
            die "a GUI picker is required: python3 with GTK 3 (gi), or kdialog."
        fi

        # One button per profile; clicking it prints the profile name and closes the window.
        pick_with_buttons() {
            python3 - "$EDITOR_LABEL" "$preselect" "${profiles[@]}" 2>/dev/null <<'PY'
import sys
import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk

editor_label = sys.argv[1]
preselect = sys.argv[2]
profiles = sys.argv[3:]
selected = []

def on_click(button, profile):
    selected.append(profile)
    Gtk.main_quit()

def on_key(window, event):
    if event.keyval == Gdk.KEY_Escape:
        Gtk.main_quit()
        return True
    return False

window = Gtk.Window(title=editor_label + " profile")
window.set_border_width(18)
window.set_resizable(False)
window.set_keep_above(True)
window.set_position(Gtk.WindowPosition.CENTER)
window.connect("destroy", Gtk.main_quit)
window.connect("key-press-event", on_key)

box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
window.add(box)

label = Gtk.Label(label="Open " + editor_label + " with profile:")
label.set_xalign(0.0)
box.pack_start(label, False, False, 0)

default_button = None
for profile in profiles:
    text = profile + ("   (last used)" if profile == preselect else "")
    button = Gtk.Button(label=text)
    button.set_can_default(True)
    button.connect("clicked", on_click, profile)
    if profile == preselect:
        button.get_style_context().add_class("suggested-action")
        default_button = button
    box.pack_start(button, False, False, 0)

window.show_all()
if default_button is not None:
    default_button.grab_focus()
    default_button.grab_default()
Gtk.main()

if selected:
    print(selected[0])
PY
        }

        # Fallback for systems without GTK 3 via gi.
        pick_with_kdialog() {
            local args=(--title "$EDITOR_LABEL profile" --geometry 400x350 --radiolist "Select a profile to open:")
            local state
            for profile in "${profiles[@]}"; do
                if [[ "$profile" == "$preselect" ]]; then state=on; else state=off; fi
                args+=("$profile" "$profile" "$state")
            done
            kdialog "${args[@]}" 2>/dev/null
        }

        if [[ "$picker" == buttons ]]; then
            choice=$(pick_with_buttons) || exit 0
        else
            choice=$(pick_with_kdialog) || exit 0
        fi
        [[ -n "$choice" ]] || exit 0
        ;;
esac

command -v "$EDITOR_BIN" >/dev/null 2>&1 ||
    die "'$EDITOR_BIN' not found in PATH (selected editor: $editor)."

mkdir -p "$CONFIG_DIR"
printf '%s\n' "$choice" > "$STATE_FILE"

if [[ "$choice" == "$DEFAULT_PROFILE" ]]; then
    exec "$EDITOR_BIN" "$@"
fi
exec "$EDITOR_BIN" --profile "$choice" "$@"
