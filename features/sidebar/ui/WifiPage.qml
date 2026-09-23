import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.sidebar.state

// Wi-Fi: liga/desliga e redes disponíveis. Clicar numa rede protegida e
// desconhecida abre o campo de senha ali mesmo.
Column {
    spacing: ThemeManager.spacing.normal

    SectionHeader {
        title: "Wi-Fi"
        subtitle: WifiState.status

        Switch {
            visible: WifiState.available
            checked: WifiState.enabled
            enabled: !WifiState.hardwareBlocked
            onToggled: on => WifiState.setEnabled(on)
        }
    }

    Txt {
        width: parent.width
        visible: WifiState.error !== ""
        text: WifiState.error
        color: ThemeManager.colors.danger
        wrapMode: Text.Wrap
        font.pixelSize: ThemeManager.font.small + 1
    }

    EmptyState {
        visible: !WifiState.available || !WifiState.enabled
        icon: Icons.wifiOff
        text: !WifiState.available ? "Nenhuma placa Wi-Fi encontrada" : "O Wi-Fi está desligado"
    }

    EmptyState {
        visible: WifiState.available && WifiState.enabled && WifiState.networks.length === 0
        icon: Icons.wifi[0]
        text: "Procurando redes…"
    }

    Column {
        width: parent.width
        visible: WifiState.enabled
        spacing: 2

        Repeater {
            model: WifiState.networks

            delegate: Column {
                id: entry

                required property var modelData
                readonly property bool open: WifiState.expanded === modelData.network

                width: parent.width
                spacing: 4

                ListRow {
                    icon: entry.modelData.icon
                    title: entry.modelData.name
                    detail: entry.modelData.connected ? "Conectada" : entry.modelData.busy ? "Conectando…" : entry.modelData.known ? "Salva" : entry.modelData.secure ? "Protegida" : "Aberta"
                    lit: entry.modelData.connected
                    busy: entry.modelData.busy
                    onClicked: WifiState.activate(entry.modelData)

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: entry.modelData.secure
                        icon: Icons.lock
                        size: 16
                        color: ThemeManager.colors.textFaint
                    }

                    IconButton {
                        visible: entry.modelData.known && parent.parent.hovered
                        icon: Icons.trash
                        iconSize: 18
                        foreground: ThemeManager.colors.textMuted
                        onClicked: WifiState.forget(entry.modelData)
                    }
                }

                // Senha, para redes protegidas ainda não salvas.
                Item {
                    width: parent.width
                    height: entry.open ? 52 : 0
                    clip: true
                    visible: height > 0

                    Behavior on height { Anim { type: Anim.FastSpatial } }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: connect.left
                        anchors.rightMargin: ThemeManager.spacing.small
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: ThemeManager.spacing.small
                        height: 42
                        radius: 21
                        color: ThemeManager.alpha(ThemeManager.colors.text, 0.06)
                        border.width: password.activeFocus ? 2 : 0
                        border.color: ThemeManager.colors.accent

                        TextInput {
                            id: password

                            anchors.fill: parent
                            anchors.leftMargin: ThemeManager.spacing.normal + 2
                            anchors.rightMargin: ThemeManager.spacing.normal
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            color: ThemeManager.colors.text
                            font.family: ThemeManager.font.sans
                            font.pixelSize: ThemeManager.font.normal
                            clip: true
                            onAccepted: WifiState.submitPassword(entry.modelData, text)

                            Txt {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !password.text
                                text: "Senha"
                                faint: true
                            }
                        }
                    }

                    TonalButton {
                        id: connect

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Conectar"
                        onClicked: WifiState.submitPassword(entry.modelData, password.text)
                    }

                    onVisibleChanged: {
                        if (visible) {
                            password.text = "";
                            password.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }
}
