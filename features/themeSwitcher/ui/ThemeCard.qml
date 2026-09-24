import QtQuick
import Quickshell.Widgets
import qs.core.theme
import qs.core.widgets

// Prévia de um tema: wallpaper, amostras de cor e nome. Desenhada com as
// cores do próprio tema, não do tema ativo.
Item {
    id: card

    required property var theme
    property bool current: false
    property bool selected: false
    readonly property var c: theme.colors

    signal clicked

    width: 200
    height: 150
    // Cresce um pouco no hover e encolhe ao pressionar.
    scale: mouse.pressed ? 0.95 : mouse.containsMouse ? 1.03 : 1

    Behavior on scale { Anim { type: Anim.FastSpatial } }

    ClippingRectangle {
        anchors.fill: parent
        radius: ThemeManager.radius.normal
        color: card.c.base ?? "black"
        border.width: ThemeManager.outlines ? 1 : 0
        border.color: card.c.border ?? "gray"

        Image {
            anchors.fill: parent
            source: ThemeManager.wallpaperFor(card.theme.id).static ? `file://${ThemeManager.wallpaperFor(card.theme.id).static}` : ""
            sourceSize: Qt.size(400, 300)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        // Mini barra, como a do shell naquele tema.
        Rectangle {
            width: parent.width
            height: 18
            color: card.c.base ?? "black"

            Row {
                anchors.verticalCenter: parent.verticalCenter
                x: 8
                spacing: 4

                Rectangle { width: 14; height: 5; radius: 2.5; color: card.c.accent ?? "white" }
                Rectangle { width: 5; height: 5; radius: 2.5; color: card.c.textMuted ?? "gray" }
                Rectangle { width: 5; height: 5; radius: 2.5; color: card.c.border ?? "gray" }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 40
            color: card.c.surface ?? "black"

            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: 10
                text: card.theme.name
                color: card.c.text ?? "white"
                font.family: ThemeManager.font.sans
                font.pixelSize: ThemeManager.font.normal
                font.weight: Font.DemiBold
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
                spacing: 4

                Repeater {
                    model: ["raised", "textMuted", "text", "accent"]

                    delegate: Rectangle {
                        required property string modelData

                        width: 12
                        height: 12
                        radius: 6
                        color: card.c[modelData] ?? "gray"
                        border.width: 1
                        border.color: card.c.border ?? "gray"
                    }
                }
            }
        }

        Rectangle {
            visible: card.current
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            anchors.topMargin: 24
            width: 22
            height: 22
            radius: 11
            color: card.c.accent ?? "white"

            Icon {
                anchors.centerIn: parent
                icon: Icons.check
                size: 14
                color: card.c.accentText ?? "black"
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked()
    }
}
