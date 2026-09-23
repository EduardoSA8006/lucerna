import QtQuick
import qs.core.theme

// Área clicável com realce de hover. Base dos botões do shell.
Rectangle {
    id: root

    property bool active: false
    readonly property bool hovered: mouse.containsMouse
    readonly property bool pressed: mouse.pressed
    property color activeColor: ThemeManager.colors.accent

    signal clicked(var mouse)
    signal wheel(var wheel)

    radius: ThemeManager.radius.small
    color: active ? activeColor
        : pressed ? ThemeManager.alpha(ThemeManager.colors.text, 0.14)
        : hovered ? ThemeManager.alpha(ThemeManager.colors.text, 0.08)
        : "transparent"
    opacity: enabled ? 1 : 0.4

    Behavior on color { ColorAnim {} }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => root.clicked(event)
        onWheel: event => root.wheel(event)
    }
}
