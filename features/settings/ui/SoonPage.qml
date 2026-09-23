import QtQuick
import qs.core.theme
import qs.core.widgets

// Tópico que ainda não tem opções.
Item {
    required property var topic

    implicitHeight: 360

    Column {
        anchors.centerIn: parent
        spacing: ThemeManager.spacing.normal

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 96
            height: 96

            Blob {
                anchors.fill: parent
                lobes: 7
                amplitude: 0.06
                color: ThemeManager.colors.track
                spinning: true
                spinDuration: 30000
            }

            Icon {
                anchors.centerIn: parent
                icon: topic.icon
                size: 40
                color: ThemeManager.colors.textFaint
            }
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Em breve"
            font.pixelSize: ThemeManager.font.large
            font.weight: Font.DemiBold
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: `As opções de ${topic.label.toLowerCase()} ainda estão sendo feitas.`
            faint: true
        }
    }
}
