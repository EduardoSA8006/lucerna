import QtQuick
import QtQuick.Layouts
import qs.core.theme
import qs.core.widgets
import qs.features.sidebar.state

// Central lateral: cartão na altura da tela que entra pela borda (direita ou
// esquerda, nas configurações). Trilho de seções do lado de fora, conteúdo do
// lado de dentro. ↑/↓ trocam de seção; Esc ou clique fora fecham; pode ficar aberta junto com outros painéis.
OverlayPanel {
    id: panel

    name: "sidebar"
    open: SidebarState.open
    screen: SidebarState.screen
    inputItem: drawer
    onDismissed: SidebarState.close()

    onOpenChanged: {
        if (open)
            rail.forceActiveFocus();
    }

    readonly property bool onLeft: SidebarState.onLeft
    readonly property real margin: SidebarState.margin

    Surface {
        id: drawer

        readonly property real travel: width + panel.margin + 24

        level: 0
        width: SidebarState.drawerWidth
        y: SidebarState.topOffset
        height: parent.height - y - panel.margin
        radius: ThemeManager.radius.large + 4
        x: panel.onLeft ? panel.margin - (1 - panel.progress) * travel : parent.width - width - panel.margin + (1 - panel.progress) * travel

        RowLayout {
            anchors.fill: parent
            spacing: 0
            layoutDirection: panel.onLeft ? Qt.LeftToRight : Qt.RightToLeft

            Rail {
                id: rail

                Layout.preferredWidth: 92
                Layout.fillHeight: true
                onLeft: panel.onLeft
                radius: drawer.radius
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                visible: ThemeManager.outlines
                color: ThemeManager.colors.border
            }

            // Conteúdo da seção
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Flickable {
                    id: scroller

                    anchors.fill: parent
                    anchors.margins: ThemeManager.spacing.large
                    contentHeight: page.height
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    Loader {
                        id: page

                        width: scroller.width
                        sourceComponent: ({
                            wifi: wifiPage,
                            bluetooth: bluetoothPage,
                            sound: soundPage,
                            notifications: inboxPage,
                            battery: batteryPage,
                            display: displayPage
                        })[SidebarState.current]

                        // A seção entra deslizando de dentro para fora da tela.
                        onLoaded: {
                            scroller.contentY = 0;
                            enter.restart();
                        }

                        transform: Translate {
                            id: pageOffset
                        }

                        ParallelAnimation {
                            id: enter

                            Anim { target: page; property: "opacity"; from: 0; to: 1; type: Anim.Effects }
                            Anim { target: pageOffset; property: "x"; from: panel.onLeft ? -24 : 24; to: 0; type: Anim.Spatial }
                        }
                    }
                }

                Rectangle {
                    visible: scroller.contentHeight > scroller.height
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    y: scroller.y + scroller.visibleArea.yPosition * scroller.height
                    width: 4
                    height: scroller.visibleArea.heightRatio * scroller.height
                    radius: 2
                    color: ThemeManager.colors.textFaint
                    opacity: scroller.moving ? 0.8 : 0.3

                    Behavior on opacity { Anim { type: Anim.Effects } }
                }
            }
        }
    }

    Component {
        id: wifiPage

        WifiPage {}
    }

    Component {
        id: bluetoothPage

        BluetoothPage {}
    }

    Component {
        id: soundPage

        SoundPage {}
    }

    Component {
        id: inboxPage

        InboxPage {}
    }

    Component {
        id: batteryPage

        BatteryPage {}
    }

    Component {
        id: displayPage

        DisplayPage {}
    }
}
