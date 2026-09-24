import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.bar.state

// Ações da barra: rede, volume, bateria e avisos. Cada uma abre a seção dela
// na central lateral.
Row {
    anchors.verticalCenter: parent?.verticalCenter
    spacing: 2

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: BarState.networkIcon
        visible: BarState.networkAvailable
        iconSize: 18
        active: BarState.sectionOpen("wifi")
        foreground: active ? ThemeManager.colors.accentText : BarState.online ? ThemeManager.colors.textMuted : ThemeManager.colors.textFaint
        onClicked: BarState.toggleSection("wifi")
    }

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: BarState.volumeIcon
        visible: BarState.audioAvailable
        iconSize: 18
        active: BarState.sectionOpen("sound")
        foreground: active ? ThemeManager.colors.accentText : BarState.muted ? ThemeManager.colors.textFaint : ThemeManager.colors.textMuted
        // Clique abre o Som; botão do meio silencia; a roda ajusta o volume.
        onClicked: event => {
            if (event.button === Qt.MiddleButton)
                BarState.toggleMute();
            else
                BarState.toggleSection("sound");
        }
        onWheel: event => BarState.scrollVolume(event.angleDelta.y / 120)
    }

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: BarState.batteryIcon
        label: BarState.batteryShowPercent ? `${BarState.batteryPercent}%` : ""
        visible: BarState.batteryAvailable
        iconSize: 18
        active: BarState.sectionOpen("battery")
        foreground: active ? ThemeManager.colors.accentText : BarState.batteryLow ? ThemeManager.colors.danger : ThemeManager.colors.textMuted
        onClicked: BarState.toggleSection("battery")
    }

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        icon: BarState.bellIcon
        iconSize: 18
        label: BarState.notificationCount > 0 ? `${BarState.notificationCount}` : ""
        active: BarState.sectionOpen("notifications")
        onClicked: BarState.toggleSection("notifications")
    }
}
