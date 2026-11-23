/*
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.15
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.plasmoid 2.0

ColumnLayout {
    spacing: Kirigami.Units.largeSpacing

    PlasmaComponents3.Label {
        text: i18n("Editor")
        font.bold: true
    }

    PlasmaComponents3.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: i18n("Choose which editor's profiles to list and launch. The editor must be installed.")
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.RadioButton {
            Layout.fillWidth: true
            text: i18n("VSCodium")
            checked: plasmoid.configuration.editor === "vscodium"
            onToggled: {
                if (checked) {
                    plasmoid.configuration.editor = "vscodium";
                }
            }
        }

        PlasmaComponents3.RadioButton {
            Layout.fillWidth: true
            text: i18n("Visual Studio Code")
            checked: plasmoid.configuration.editor === "vscode"
            onToggled: {
                if (checked) {
                    plasmoid.configuration.editor = "vscode";
                }
            }
        }
    }

    PlasmaComponents3.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        opacity: 0.7
        text: i18n("Each editor keeps its own profile list and last-used selection.")
    }

    Item {
        Layout.fillHeight: true
    }
}
