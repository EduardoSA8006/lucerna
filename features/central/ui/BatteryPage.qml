pragma ComponentBehavior: Bound

import QtQuick
import qs.core.format
import qs.core.theme
import qs.core.widgets
import qs.features.central.state

// Página da bateria no painel de ações da central: voltar e o título; a
// bateria em destaque (a porcentagem grande, o tempo ou "Carregando" e uma
// barra), o perfil de energia em botões de ícone (o atual cheio) e a bateria
// dos dispositivos Bluetooth conectados. Sem bateria, sem perfil ou sem
// dispositivos, o bloco some.
Column {
    id: root

    width: parent?.width ?? 0
    spacing: ThemeManager.spacing.small

    PageHeader {
        title: PowerState.title
        onBack: CentralState.setPage("")
    }

    Group {
        visible: PowerState.hasBattery

        Column {
            x: ThemeManager.spacing.small
            width: parent.width - x * 2
            topPadding: ThemeManager.spacing.tiny
            bottomPadding: ThemeManager.spacing.normal
            spacing: ThemeManager.spacing.small

            Row {
                spacing: ThemeManager.spacing.small

                Txt {
                    id: charge

                    text: Format.percent(PowerState.percentage)
                    mono: true
                    font.pixelSize: ThemeManager.font.huge - 8
                    font.weight: Font.DemiBold
                }

                Txt {
                    anchors.baseline: charge.baseline
                    text: PowerState.batteryNote
                    muted: true
                }
            }

            LinearGauge {
                width: parent.width
                height: 10
                value: PowerState.percentage
                color: PowerState.charging ? ThemeManager.colors.success : PowerState.low ? ThemeManager.colors.danger : ThemeManager.colors.accent
            }
        }
    }

    Row {
        id: profiles

        visible: PowerState.profilesAvailable
        width: parent.width
        spacing: ThemeManager.spacing.small

        // Pela quantidade, como os outros botões: cada um lê o seu perfil.
        Repeater {
            model: PowerState.profileButtons.length

            delegate: ToggleButton {
                id: profile

                required property int index
                readonly property var item: PowerState.profileButtons[profile.index] ?? null

                width: (profiles.width - profiles.spacing * (PowerState.profileButtons.length - 1)) / PowerState.profileButtons.length
                height: 44
                icon: profile.item?.icon ?? ""
                checked: profile.item?.value === PowerState.profile
                onClicked: PowerState.setProfile(profile.item?.value ?? PowerState.profile)
            }
        }
    }

    Group {
        visible: PowerState.devices.length > 0

        // Pela quantidade, como os botões e os volumes: a bateria que muda
        // refaz a lista, mas não recria as linhas.
        Repeater {
            model: PowerState.devices.length

            delegate: Item {
                id: device

                required property int index
                readonly property var item: PowerState.devices[device.index] ?? null

                width: parent?.width ?? 0
                height: 44

                Icon {
                    id: deviceIcon

                    x: ThemeManager.spacing.small
                    anchors.verticalCenter: parent.verticalCenter
                    icon: device.item?.icon ?? ""
                    size: 20
                    color: ThemeManager.colors.textMuted
                }

                Txt {
                    anchors.left: deviceIcon.right
                    anchors.leftMargin: ThemeManager.spacing.normal
                    anchors.right: percent.left
                    anchors.rightMargin: ThemeManager.spacing.small
                    anchors.verticalCenter: parent.verticalCenter
                    text: device.item?.name ?? ""
                }

                Txt {
                    id: percent

                    anchors.right: parent.right
                    anchors.rightMargin: ThemeManager.spacing.small
                    anchors.verticalCenter: parent.verticalCenter
                    text: Format.percent(device.item?.battery ?? 0)
                    mono: true
                    muted: true
                }
            }
        }
    }
}
