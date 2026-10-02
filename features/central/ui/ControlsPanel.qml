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

        // Os botões dividem a linha. O modelo é a quantidade: ligar um botão
        // refaz a lista, mas não recria os botões (a onda e a cor seguem).
        Row {
            id: toggles

            readonly property int count: ControlsState.toggles.length
            readonly property real cell: (width - spacing * (count - 1)) / Math.max(1, count)

            width: parent.width
            spacing: ThemeManager.spacing.small

            Repeater {
                model: toggles.count

                delegate: ToggleButton {
                    id: toggle

                    required property int index
                    readonly property var item: ControlsState.toggles[toggle.index] ?? null

                    width: toggles.cell
                    height: 64
                    icon: toggle.item?.icon ?? ""
                    checked: toggle.item?.checked ?? false
                    onClicked: ControlsState.trigger(toggle.item?.id ?? "")
                }
            }
        }
    }

    Component {
        id: network

        Column {
            // Sem placa Wi-Fi (desktop com cabo), a linha só informa.
            ListRow {
                icon: WifiState.icon
                title: WifiState.summary
                detail: WifiState.available ? "Wi-Fi" : "Rede"
                lit: WifiState.connected
                enabled: WifiState.available
                opacity: 1
                onClicked: CentralState.setControlsPage("wifi")

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: WifiState.available
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
