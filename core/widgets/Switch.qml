import QtQuick
import qs.core.theme

// Interruptor no estilo do Material 3: desligado, um polegar pequeno num trilho
// vazado; ligado, o polegar cresce, desliza com mola e ganha um ✓.
// Controlado: emite `toggled` e quem usa decide o novo `checked`.
Item {
    id: root

    property bool checked: false

    signal toggled(bool checked)

    implicitWidth: 52
    implicitHeight: 32
    activeFocusOnTab: true

    function toggle(): void {
        toggled(!checked);
    }

    Keys.onSpacePressed: toggle()
    Keys.onReturnPressed: toggle()

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? ThemeManager.colors.accent : "transparent"
        border.width: root.checked ? 0 : 2
        border.color: ThemeManager.colors.textFaint

        Behavior on color { ColorAnim {} }
    }

    Rectangle {
        id: thumb

        property real size: mouse.pressed ? 28 : root.checked ? 24 : 16

        width: size
        height: size
        radius: size / 2
        x: root.checked ? root.width - 4 - size : 8 + (16 - size) / 2
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? ThemeManager.colors.accentText : ThemeManager.colors.textMuted

        Behavior on x { Anim { type: Anim.FastSpatial } }
        Behavior on size { Anim { type: Anim.FastSpatial } }
        Behavior on color { ColorAnim {} }

        // Véu de hover em volta do polegar.
        Rectangle {
            anchors.centerIn: parent
            width: 40
            height: 40
            radius: 20
            color: ThemeManager.colors.text
            opacity: mouse.containsMouse || root.activeFocus ? 0.08 : 0
            z: -1

            Behavior on opacity { Anim { type: Anim.FastEffects } }
        }

        Icon {
            anchors.centerIn: parent
            icon: Icons.check
            size: 16
            weight: 600
            color: ThemeManager.colors.accent
            opacity: root.checked ? 1 : 0
            scale: root.checked ? 1 : 0.4

            Behavior on opacity { Anim { type: Anim.FastEffects } }
            Behavior on scale { Anim { type: Anim.FastSpatial } }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggle()
    }
}
