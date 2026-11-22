/*
 * SPDX-License-Identifier: MIT
 */

import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls
import Qt.labs.folderlistmodel
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.plasmoid 2.0

ColumnLayout {
    id: configPage

    spacing: Kirigami.Units.largeSpacing

    PlasmaComponents3.Label {
        text: i18n("Panel icon")
        font.bold: true
    }

    PlasmaComponents3.Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: i18n("Choose one of the default icons, a theme icon name, or any image path.")
    }

    FolderListModel {
        id: iconsModel
        folder: "file:///home/ftristan/Scripts/VSProfiler/icons"
        nameFilters: ["*.png", "*.svg"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 4
        rowSpacing: Kirigami.Units.smallSpacing
        columnSpacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.ToolButton {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            Layout.preferredHeight: Kirigami.Units.gridUnit * 5
            icon.name: "vscodium"
            icon.width: Kirigami.Units.iconSizes.large
            icon.height: Kirigami.Units.iconSizes.large
            text: i18n("Theme")
            display: AbstractButton.TextUnderIcon
            checked: plasmoid.configuration.iconSource === "vscodium"
            onClicked: plasmoid.configuration.iconSource = "vscodium"
        }

        Repeater {
            model: iconsModel

            delegate: PlasmaComponents3.ToolButton {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                checked: plasmoid.configuration.iconSource === String(model.fileUrl)
                onClicked: plasmoid.configuration.iconSource = String(model.fileUrl)

                contentItem: Column {
                    spacing: Kirigami.Units.smallSpacing
                    anchors.centerIn: parent

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: model.fileUrl
                        width: Kirigami.Units.iconSizes.large
                        height: Kirigami.Units.iconSizes.large
                        fillMode: Image.PreserveAspectFit
                    }

                    PlasmaComponents3.Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Kirigami.Units.gridUnit * 5
                        text: model.fileName
                        elide: Text.ElideMiddle
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.7)
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            text: i18n("Custom:")
        }

        PlasmaComponents3.TextField {
            id: customIcon
            Layout.fillWidth: true
            text: plasmoid.configuration.iconSource
            placeholderText: i18n("Icon name or image path")
            onEditingFinished: {
                plasmoid.configuration.iconSource = text;
                text = Qt.binding(function () { return plasmoid.configuration.iconSource; });
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}
