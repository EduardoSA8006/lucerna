import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core.theme
import qs.core.widgets
import qs.features.bar.state

PanelWindow {
    id: root

    required property var modelData

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: ThemeManager.barHeight
    color: ThemeManager.glass(ThemeManager.colors.base, 0)
    WlrLayershell.namespace: "lucerna-panel-bar"

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        color: ThemeManager.colors.border
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: ThemeManager.spacing.small
            rightMargin: ThemeManager.spacing.small
        }
        spacing: ThemeManager.spacing.small

        IconButton {
            icon: Icons.apps
            active: BarState.openPanel === "launcher"
            onClicked: BarState.togglePanel("launcher")
        }

        Workspaces {}

        Item {
            Layout.fillWidth: true
        }

        IconButton {
            icon: BarState.networkIcon
            visible: BarState.networkAvailable
            foreground: BarState.online ? ThemeManager.colors.textMuted : ThemeManager.colors.textFaint
        }

        IconButton {
            icon: BarState.volumeIcon
            label: BarState.muted ? "" : `${BarState.volumePercent}%`
            visible: BarState.audioAvailable
            foreground: BarState.muted ? ThemeManager.colors.textFaint : ThemeManager.colors.text
            onClicked: BarState.toggleMute()
            onWheel: event => BarState.scrollVolume(event.angleDelta.y / 120)
        }

        IconButton {
            icon: BarState.batteryIcon
            label: `${BarState.batteryPercent}%`
            visible: BarState.batteryAvailable
            foreground: BarState.batteryLow ? ThemeManager.colors.danger : ThemeManager.colors.text
        }

        IconButton {
            icon: BarState.bellIcon
            label: BarState.notificationCount > 0 ? `${BarState.notificationCount}` : ""
            active: BarState.openPanel === "notifications"
            onClicked: BarState.togglePanel("notifications")
        }

        IconButton {
            icon: Icons.palette
            active: BarState.openPanel === "themes"
            onClicked: BarState.togglePanel("themes")
        }

        IconButton {
            icon: Icons.power
            active: BarState.openPanel === "power"
            onClicked: BarState.togglePanel("power")
        }
    }

    // Relógio centralizado na tela, independente da largura dos lados. Abre o painel superior.
    Clickable {
        anchors.centerIn: parent
        width: clock.implicitWidth + ThemeManager.spacing.normal * 2
        height: ThemeManager.barHeight - ThemeManager.spacing.small
        active: BarState.openPanel === "dashboard"
        activeColor: ThemeManager.alpha(ThemeManager.colors.accent, 0.16)
        onClicked: BarState.togglePanel("dashboard")
    }

    Row {
        id: clock

        anchors.centerIn: parent
        spacing: ThemeManager.spacing.small

        Txt {
            text: BarState.time
            mono: true
            font.weight: Font.DemiBold
        }

        Txt {
            text: BarState.date
            muted: true
        }
    }
}
