pragma ComponentBehavior: Bound

import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.central.state

// Bluetooth no card de controles da central: voltar, o título e o
// liga/desliga no topo; embaixo, procurar, os pareados e, procurando, os
// disponíveis, que rolam dentro de `maxListHeight`.
Column {
    id: root

    property real maxListHeight: 360

    width: parent?.width ?? 0
    spacing: ThemeManager.spacing.small

    PageHeader {
        title: "Bluetooth"
        onBack: CentralState.setControlsPage("")

        Switch {
            visible: BluetoothState.available
            checked: BluetoothState.enabled
            onToggled: on => BluetoothState.setEnabled(on)
        }
    }

    EmptyState {
        visible: !BluetoothState.available || !BluetoothState.enabled
        icon: Icons.bluetoothOff
        text: !BluetoothState.available ? "Nenhum adaptador Bluetooth encontrado" : "O Bluetooth está desligado"
    }

    TonalButton {
        visible: BluetoothState.enabled
        icon: BluetoothState.searching ? Icons.bluetoothSearching : Icons.sync
        text: BluetoothState.searching ? "Parar de procurar" : "Procurar dispositivos"
        onClicked: BluetoothState.toggleSearch()
    }

    Flickable {
        width: root.width
        height: Math.min(devices.implicitHeight, root.maxListHeight)
        visible: BluetoothState.enabled
        contentHeight: devices.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: devices

            width: root.width
            spacing: 2

            Txt {
                visible: BluetoothState.paired.length > 0
                text: "PAREADOS"
                faint: true
                font.pixelSize: ThemeManager.font.small
                font.weight: Font.DemiBold
                font.letterSpacing: 1
            }

            Repeater {
                model: BluetoothState.paired

                delegate: ListRow {
                    id: row

                    required property var modelData

                    icon: row.modelData.icon
                    title: row.modelData.name
                    detail: row.modelData.busy ? "Conectando…" : row.modelData.detail
                    lit: row.modelData.connected
                    busy: row.modelData.busy
                    onClicked: BluetoothState.toggleConnection(row.modelData)

                    IconButton {
                        visible: row.hovered
                        icon: Icons.trash
                        iconSize: 18
                        foreground: ThemeManager.colors.textMuted
                        onClicked: BluetoothState.forget(row.modelData)
                    }
                }
            }

            Txt {
                visible: BluetoothState.searching
                text: "DISPONÍVEIS"
                faint: true
                font.pixelSize: ThemeManager.font.small
                font.weight: Font.DemiBold
                font.letterSpacing: 1
            }

            Txt {
                visible: BluetoothState.searching && BluetoothState.others.length === 0
                text: "Procurando…"
                muted: true
            }

            Repeater {
                model: BluetoothState.searching ? BluetoothState.others : []

                delegate: ListRow {
                    id: other

                    required property var modelData

                    icon: other.modelData.icon
                    title: other.modelData.name
                    detail: other.modelData.busy ? "Pareando…" : "Toque para parear"
                    busy: other.modelData.busy
                    onClicked: BluetoothState.toggleConnection(other.modelData)
                }
            }
        }
    }
}
