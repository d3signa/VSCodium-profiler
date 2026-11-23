import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
        name: i18n("Editor")
        icon: "applications-development"
        source: "configEditor.qml"
    }

    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-theme"
        source: "configIcon.qml"
    }
}
