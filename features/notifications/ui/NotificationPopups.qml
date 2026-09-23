import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.theme
import qs.features.notifications.state

// Popups no canto superior direito do monitor com foco. Somem quando a
// central está aberta (as notificações continuam lá).
PanelWindow {
    id: window

    screen: NotificationsState.screen
    visible: NotificationsState.popups.length > 0
    anchors {
        top: true
        right: true
    }
    margins {
        top: ThemeManager.spacing.small
        right: ThemeManager.spacing.small
    }
    implicitWidth: 380
    implicitHeight: Math.max(1, column.implicitHeight)
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lucerna-notifications"

    Column {
        id: column

        width: parent.width
        spacing: ThemeManager.spacing.small

        Repeater {
            model: NotificationsState.popups

            delegate: NotificationCard {
                id: popupCard

                required property var modelData

                width: column.width
                notification: modelData
                popup: true
                onExpired: NotificationsState.hidePopup(modelData)

                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: ThemeManager.anim.normal } }
            }
        }
    }
}
