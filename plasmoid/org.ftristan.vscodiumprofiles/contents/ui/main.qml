/*
 * SPDX-License-Identifier: MIT
 * Based on org.kde.plasma.konsoleprofiles
 */

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasma5support 2.0 as P5Support

PlasmoidItem {
    id: root

    // Path to the helper script that discovers and launches profiles.
    property string helper: "/home/ftristan/Scripts/VSProfiler/vscodium-profile.sh"
    property var profiles: []
    property string lastProfile: "Default"
    property string iconSource: plasmoid.configuration.iconSource || "vscodium"
    property string editor: plasmoid.configuration.editor || "vscodium"
    // Plasmoid.icon only accepts theme icon names, so keep a valid fallback for
    // file-based icons while the custom compact representation shows the real image.
    property string appletIconName: isFileIcon(iconSource) ? "vscodium" : iconSource

    readonly property bool inPanel: (Plasmoid.location === PlasmaCore.Types.TopEdge
        || Plasmoid.location === PlasmaCore.Types.RightEdge
        || Plasmoid.location === PlasmaCore.Types.BottomEdge
        || Plasmoid.location === PlasmaCore.Types.LeftEdge)

    switchWidth: Kirigami.Units.gridUnit * 11
    switchHeight: Kirigami.Units.gridUnit * 9

    Layout.minimumWidth: Kirigami.Units.gridUnit * 12
    Layout.minimumHeight: Kirigami.Units.gridUnit * 10

    Plasmoid.icon: root.appletIconName

    function isFileIcon(source) {
        var value = String(source || "");
        return value.indexOf("/") !== -1 || value.indexOf(":\\") !== -1;
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    function helperCmd(arguments) {
        return shellQuote(helper) + " --editor " + shellQuote(editor) + " " + arguments;
    }

    function refresh() {
        listSource.connectSource(helperCmd("--list-profiles"));
        lastSource.connectSource(helperCmd("--last-profile"));
    }

    function openProfile(name) {
        launchSource.connectSource(helperCmd("--profile " + shellQuote(name)));
        plasmoid.expanded = false;
        refreshTimer.start();
    }

    P5Support.DataSource {
        id: listSource
        engine: "executable"
        connectedSources: []
        interval: 0

        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            if (data["exit code"] !== 0) {
                return;
            }
            var output = data["stdout"] || "";
            var names = output.split(/\r?\n/).filter(function (line) {
                return line.trim().length > 0;
            });
            if (names.length > 0) {
                root.profiles = names;
            }
        }
    }

    P5Support.DataSource {
        id: lastSource
        engine: "executable"
        connectedSources: []
        interval: 0

        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            var output = (data["stdout"] || "").trim();
            if (output.length > 0) {
                root.lastProfile = output;
            }
        }
    }

    P5Support.DataSource {
        id: launchSource
        engine: "executable"
        connectedSources: []
        interval: 0

        onNewData: (sourceName, data) => disconnectSource(sourceName)
    }

    Timer {
        id: refreshTimer
        interval: 1000
        onTriggered: refresh()
    }

    Component.onCompleted: refresh()

    Connections {
        target: plasmoid.configuration
        function onEditorChanged() { refresh() }
    }

    compactRepresentation: MouseArea {
        id: compactMouse
        anchors.fill: parent
        activeFocusOnTab: true
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        Accessible.name: Plasmoid.title
        Accessible.description: i18n("Open the profile picker")
        Accessible.role: Accessible.Button

        property bool wasExpanded: false
        onPressed: wasExpanded = root.expanded
        onClicked: root.expanded = !wasExpanded

        Kirigami.Icon {
            anchors.fill: parent
            source: root.iconSource
            fallback: "vscodium"
            active: compactMouse.containsMouse
        }
    }

    fullRepresentation: FocusScope {
        anchors.fill: parent

        Connections {
            target: root
            function onExpandedChanged() {
                if (root.expanded) {
                    view.forceActiveFocus();
                    refresh();
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Row {
                id: headerRow
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium + Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: root.iconSource
                    fallback: "vscodium"
                    width: Kirigami.Units.iconSizes.medium
                    height: Kirigami.Units.iconSizes.medium
                    anchors.verticalCenter: parent.verticalCenter
                }

                PlasmaComponents3.Label {
                    text: editor === "vscode" ? i18nc("@title", "VS Code Profiles") : i18nc("@title", "VSCodium Profiles")
                    textFormat: Text.PlainText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    width: parent.width - Kirigami.Units.iconSizes.medium * 2
                    height: parent.height
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Kirigami.Theme.textColor
                opacity: 0.2
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Kirigami.Units.smallSpacing

                ListView {
                    id: view
                    model: root.profiles
                    clip: true
                    focus: true
                    keyNavigationWraps: true

                    delegate: PlasmaComponents3.ItemDelegate {
                        width: ListView.view.width
                        text: modelData + (modelData === root.lastProfile ? "   (last used)" : "")
                        hoverEnabled: true
                        Accessible.role: Accessible.Button
                        onClicked: root.openProfile(modelData)
                        onHoveredChanged: {
                            if (hovered) {
                                view.currentIndex = index;
                            }
                        }
                    }

                    highlight: PlasmaExtras.Highlight {}
                    highlightMoveDuration: Kirigami.Units.longDuration
                    highlightMoveVelocity: 1
                }
            }
        }
    }
}
