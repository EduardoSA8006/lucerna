import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.settings.state

// Atalhos: referência das teclas e dos comandos IPC equivalentes.
Column {
    spacing: ThemeManager.spacing.large

    Txt {
        width: parent.width
        wrapMode: Text.Wrap
        muted: true
        text: "Os atalhos ficam no hyprland.lua e chamam o shell por IPC (qs -c lucerna ipc call …). Mod é Super no seu sistema e Alt no ambiente de desenvolvimento."
    }

    SettingSection {
        title: "Teclas"

        Repeater {
            model: SettingsState.shortcuts

            delegate: SettingRow {
                required property var modelData
                required property int index

                title: modelData.action
                description: modelData.command

                Rectangle {
                    width: keysText.implicitWidth + 20
                    height: 30
                    radius: 8
                    color: ThemeManager.glass(ThemeManager.colors.raised, 1)
                    border.width: ThemeManager.outlines ? 1 : 0
                    border.color: ThemeManager.colors.border

                    Txt {
                        id: keysText

                        anchors.centerIn: parent
                        text: modelData.keys
                        mono: true
                        font.pixelSize: ThemeManager.font.small + 1
                    }
                }
            }
        }
    }
}
