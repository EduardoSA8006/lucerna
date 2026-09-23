import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.sidebar.state

// Bluetooth: liga/desliga, dispositivos pareados e, ao procurar, os disponíveis.
Column {
    spacing: ThemeManager.spacing.normal

    SectionHeader {
        title: "Bluetooth"
        subtitle: BluetoothState.status

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

    Column {
        width: parent.width
        visible: BluetoothState.enabled
        spacing: ThemeManager.spacing.normal

        TonalButton {
            icon: BluetoothState.searching ? Icons.bluetoothSearching : Icons.sync
            text: BluetoothState.searching ? "Parar de procurar" : "Procurar dispositivos"
            onClicked: BluetoothState.toggleSearch()
        }

        Txt {
            visible: BluetoothState.paired.length > 0
            text: "PAREADOS"
            faint: true
            font.pixelSize: ThemeManager.font.small
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: BluetoothState.paired

                delegate: ListRow {
                    id: row

                    required property var modelData

                    icon: modelData.icon
                    title: modelData.name
                    detail: modelData.busy ? "Conectando…" : modelData.detail
                    lit: modelData.connected
                    busy: modelData.busy
                    onClicked: BluetoothState.toggleConnection(modelData)

                    IconButton {
                        visible: row.hovered
                        icon: Icons.trash
                        iconSize: 18
                        foreground: ThemeManager.colors.textMuted
                        onClicked: BluetoothState.forget(row.modelData)
                    }
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

        Column {
            width: parent.width
            visible: BluetoothState.searching
            spacing: 2

            Repeater {
                model: BluetoothState.others

                delegate: ListRow {
                    required property var modelData

                    icon: modelData.icon
                    title: modelData.name
                    detail: modelData.busy ? "Pareando…" : "Toque para parear"
                    busy: modelData.busy
                    onClicked: BluetoothState.toggleConnection(modelData)
                }
            }
        }
    }
}
