import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.settings.state

// Sobre: o shell, as versões e as dependências.
Column {
    spacing: ThemeManager.spacing.large

    Row {
        spacing: ThemeManager.spacing.large

        Item {
            width: 84
            height: 84

            Blob {
                anchors.fill: parent
                lobes: 8
                amplitude: 0.07
                color: ThemeManager.alpha(ThemeManager.colors.accent, 0.2)
                spinning: true
            }

            Icon {
                anchors.centerIn: parent
                icon: "emoji_objects"
                filled: true
                size: 40
                color: ThemeManager.colors.accent
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Txt {
                text: "Lucerna"
                font.pixelSize: ThemeManager.font.huge - 12
                font.weight: Font.DemiBold
            }

            Txt {
                text: "Shell de desktop para o Hyprland, escrito em Quickshell"
                muted: true
            }
        }
    }

    SettingSection {
        title: "Sistema"

        Repeater {
            model: SettingsState.about

            delegate: SettingRow {
                required property var modelData

                title: modelData.label

                Txt {
                    text: modelData.value
                    mono: true
                    muted: true
                    font.pixelSize: ThemeManager.font.small + 1
                }
            }
        }
    }

    SettingSection {
        title: "Dependências"

        SettingRow {
            title: "Obrigatórias"
            description: "Hyprland 0.56+ (config em Lua), Quickshell 0.3.1+ e a fonte Material Symbols"
        }

        SettingRow {
            title: "Opcionais"
            description: "PipeWire, UPower, NetworkManager, brightnessctl e nvidia-smi"
        }

        SettingRow {
            title: "Serviços na internet"
            description: "Open-Meteo (clima) e LRCLIB (letras), só com a aba correspondente aberta"
        }
    }
}
