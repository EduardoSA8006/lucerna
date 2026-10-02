import QtQuick
import qs.core.format
import qs.core.theme
import qs.core.widgets

// Saída ou entrada de som: o ícone (clicar silencia; o ícone mostra o mudo),
// o nome do dispositivo, a porcentagem e a setinha que abre a lista de
// dispositivos; embaixo, o volume.
Column {
    id: root

    property string icon
    property string name
    property real value: 0
    property bool muted: false

    signal moved(real value)
    signal muteClicked
    signal listClicked

    width: parent?.width ?? 0

    Item {
        width: parent.width
        height: 44

        Clickable {
            id: tile

            x: ThemeManager.spacing.tiny
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            radius: ThemeManager.radius.small
            onClicked: root.muteClicked()

            Icon {
                anchors.centerIn: parent
                icon: root.icon
                size: 20
                filled: tile.hovered
                color: root.muted ? ThemeManager.colors.textFaint : ThemeManager.colors.textMuted
            }
        }

        Txt {
            anchors.left: tile.right
            anchors.leftMargin: ThemeManager.spacing.small
            anchors.right: percent.left
            anchors.rightMargin: ThemeManager.spacing.small
            anchors.verticalCenter: parent.verticalCenter
            text: root.name
            font.weight: Font.Medium
        }

        Txt {
            id: percent

            anchors.right: more.left
            anchors.rightMargin: ThemeManager.spacing.tiny
            anchors.verticalCenter: parent.verticalCenter
            text: Format.percent(root.value)
            mono: true
            muted: true
            font.pixelSize: ThemeManager.font.small + 1
        }

        IconButton {
            id: more

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.chevronRight
            iconSize: 20
            implicitWidth: 32
            implicitHeight: 32
            radius: 16
            foreground: ThemeManager.colors.textMuted
            onClicked: root.listClicked()
        }
    }

    Slider {
        x: tile.x + tile.width + ThemeManager.spacing.small
        width: parent.width - x - ThemeManager.spacing.small
        value: root.value
        opacity: root.muted ? 0.5 : 1
        onMoved: v => root.moved(v)
    }
}
