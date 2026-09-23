import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.theme
import qs.core.widgets
import qs.features.notifications.state

// Popups no canto superior direito do monitor com foco. Entram e saem
// deslizando pela direita; os de baixo se reacomodam com mola.
//
// A janela ocupa a coluna inteira, mas só a área dos cartões recebe cliques
// (máscara), e ela só existe enquanto há popups (mais o tempo da animação de
// saída do último).
PanelWindow {
    id: window

    readonly property bool hasPopups: NotificationsState.popups.length > 0

    onHasPopupsChanged: {
        if (!hasPopups)
            linger.restart();
    }

    Timer {
        id: linger

        interval: 600
    }

    visible: hasPopups || linger.running
    screen: NotificationsState.screen
    anchors {
        top: true
        right: true
        bottom: true
    }
    margins {
        top: ThemeManager.spacing.small
        right: ThemeManager.spacing.small
    }
    implicitWidth: 380
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    mask: Region {
        item: list.contentItem
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lucerna-panel-notifications"

    ListView {
        id: list

        anchors.fill: parent
        spacing: ThemeManager.spacing.small
        interactive: false

        model: ScriptModel {
            values: NotificationsState.popups
        }

        delegate: NotificationCard {
            required property var modelData

            width: ListView.view.width
            notification: modelData
            popup: true
            onExpired: NotificationsState.hidePopup(modelData)
        }

        add: Transition {
            ParallelAnimation {
                Anim { property: "x"; from: 64; to: 0; type: Anim.Spatial }
                Anim { property: "opacity"; from: 0; to: 1; type: Anim.Effects }
            }
        }

        remove: Transition {
            ParallelAnimation {
                Anim { property: "x"; to: 96; type: Anim.EmphasizedAccel }
                Anim { property: "opacity"; to: 0; type: Anim.EmphasizedAccel }
            }
        }

        displaced: Transition {
            Anim { properties: "x,y"; type: Anim.Spatial }
            Anim { property: "opacity"; to: 1; type: Anim.Effects }
        }
    }
}
