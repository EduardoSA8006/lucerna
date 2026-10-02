pragma ComponentBehavior: Bound

import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.central.state

// Controles da central: o card de rede (Wi-Fi e Bluetooth; a linha troca o
// card inteiro pela página do recurso), o brilho da tela em foco e os botões
// de ícone, cheios quando ligados.
CentralPanel {
    id: root

    // Altura máxima da lista numa página do card (redes, dispositivos): o
    // resto da coluna fica para as notificações. Quem usa ajusta à tela.
    property real maxListHeight: 360

    height: column.implicitHeight + padding * 2

    Column {
        id: column

        width: parent.width
        spacing: ThemeManager.spacing.small

        Group {
            Loader {
                id: card

                width: parent.width
                sourceComponent: CentralState.controlsPage === "wifi" ? wifiPage : CentralState.controlsPage === "bluetooth" ? bluetoothPage : network
                onLoaded: pageIn.restart()

                transform: Translate {
                    id: cardOffset
                }

                // A página entra pela direita; a volta, pela esquerda.
                ParallelAnimation {
                    id: pageIn

                    Anim { target: card; property: "opacity"; from: 0; to: 1; type: Anim.Effects }
                    Anim { target: cardOffset; property: "x"; from: CentralState.controlsPage ? 16 : -16; to: 0; type: Anim.Spatial }
                }
            }
        }

        Group {
            visible: ControlsState.hasBrightness

            LevelRow {
                icon: Icons.brightnessMedium
                from: 0.01
                value: ControlsState.brightness
                onMoved: v => ControlsState.setBrightness(v)
            }
        }

        // Quatro colunas sempre: sem um recurso, os outros não esticam.
        Row {
            id: toggles

            readonly property real cell: (width - spacing * 3) / 4

            width: parent.width
            spacing: ThemeManager.spacing.small

            Repeater {
                model: ControlsState.toggles

                delegate: ToggleButton {
                    id: toggle

                    required property var modelData

                    width: toggles.cell
                    height: toggles.cell
                    icon: toggle.modelData.icon
                    checked: toggle.modelData.checked
                    onClicked: ControlsState.trigger(toggle.modelData.id)
                }
            }
        }
    }

    Component {
        id: network

        Column {
            ListRow {
                icon: WifiState.icon
                title: WifiState.summary
                detail: "Wi-Fi"
                lit: WifiState.connected
                onClicked: CentralState.setControlsPage("wifi")

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Icons.chevronRight
                    size: 20
                    color: ThemeManager.colors.textMuted
                }
            }

            ListRow {
                icon: BluetoothState.icon
                title: BluetoothState.summary
                detail: "Bluetooth"
                lit: BluetoothState.connected
                onClicked: CentralState.setControlsPage("bluetooth")

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Icons.chevronRight
                    size: 20
                    color: ThemeManager.colors.textMuted
                }
            }
        }
    }

    Component {
        id: wifiPage

        WifiPage {
            maxListHeight: root.maxListHeight
        }
    }

    Component {
        id: bluetoothPage

        BluetoothPage {
            maxListHeight: root.maxListHeight
        }
    }
}
