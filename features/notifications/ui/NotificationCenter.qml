import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core.theme
import qs.core.widgets
import qs.features.notifications.state

// Central lateral: histórico, "não perturbe" e limpar tudo.
OverlayPanel {
    id: panel

    name: "notification-center"
    open: NotificationsState.centerOpen
    screen: NotificationsState.screen
    dim: 0.2
    onDismissed: NotificationsState.close()

    Surface {
        id: drawer

        width: 400
        anchors {
            top: parent.top
            bottom: parent.bottom
            topMargin: ThemeManager.barHeight + ThemeManager.spacing.small
            bottomMargin: ThemeManager.spacing.small
        }
        x: parent.width - width - ThemeManager.spacing.small + (1 - panel.progress) * 40

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ThemeManager.spacing.normal
            spacing: ThemeManager.spacing.normal

            RowLayout {
                Layout.fillWidth: true
                spacing: ThemeManager.spacing.tiny

                Txt {
                    Layout.fillWidth: true
                    text: "Notificações"
                    font.pixelSize: ThemeManager.font.large
                    font.weight: Font.DemiBold
                }

                IconButton {
                    icon: NotificationsState.doNotDisturb ? Icons.bellSleep : Icons.bellOutline
                    label: NotificationsState.doNotDisturb ? "Não perturbe" : ""
                    active: NotificationsState.doNotDisturb
                    onClicked: NotificationsState.toggleDoNotDisturb()
                }

                IconButton {
                    icon: Icons.clearAll
                    enabled: NotificationsState.list.length > 0
                    onClicked: NotificationsState.clearAll()
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: ThemeManager.spacing.small
                model: NotificationsState.list
                boundsBehavior: Flickable.StopAtBounds

                delegate: NotificationCard {
                    required property var modelData

                    width: ListView.view.width
                    notification: modelData
                }

                add: Transition {
                    Anim { property: "opacity"; from: 0; to: 1; type: Anim.Effects }
                }
                displaced: Transition {
                    Anim { property: "y"; type: Anim.Spatial }
                }

                Column {
                    anchors.centerIn: parent
                    visible: NotificationsState.list.length === 0
                    spacing: ThemeManager.spacing.small

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        icon: Icons.bellOutline
                        size: 36
                        color: ThemeManager.colors.textFaint
                    }

                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Nada por aqui"
                        faint: true
                    }
                }
            }
        }
    }
}
