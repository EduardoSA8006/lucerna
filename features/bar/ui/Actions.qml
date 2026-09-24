import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.bar.state

// Ações da barra: rede, volume, bateria e avisos. Cada uma abre a seção dela
// na central lateral. Gravando a tela, aparece antes o tempo, que para ao clicar.
Row {
    anchors.verticalCenter: parent?.verticalCenter
    spacing: 2

    Clickable {
        anchors.verticalCenter: parent.verticalCenter
        visible: BarState.recording
        width: recRow.implicitWidth + 18
        height: 28
        radius: 14
        color: ThemeManager.colors.danger
        onClicked: BarState.stopRecording()

        Row {
            id: recRow

            anchors.centerIn: parent
            spacing: 5

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: ThemeManager.colors.accentText

                SequentialAnimation on opacity {
                    running: BarState.recording
                    loops: Animation.Infinite

                    NumberAnimation { to: 0.3; duration: 700 }
                    NumberAnimation { to: 1; duration: 700 }
                }
            }

            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: BarState.recordingTime
                mono: true
                color: ThemeManager.colors.accentText
                font.pixelSize: ThemeManager.font.small + 1
                font.weight: Font.DemiBold
            }

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                icon: "stop"
                filled: true
                size: 16
                color: ThemeManager.colors.accentText
            }
        }
    }

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
