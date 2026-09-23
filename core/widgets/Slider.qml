import QtQuick
import qs.core.theme

// Controle deslizante no estilo do Material 3 mais recente: trilho grosso, uma
// alça em barra no meio e uma folga dos dois lados dela. Enquanto arrasta,
// um balão mostra o valor. Controlado: emite `moved` e quem usa decide `value`.
Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    property real stepSize: 0
    // Texto do balão para um valor.
    property var format: v => `${Math.round(v * 100)}%`

    signal moved(real value)

    readonly property real fraction: Math.max(0, Math.min(1, (value - from) / (to - from)))
    readonly property bool dragging: mouse.pressed
    property real shownFraction: fraction
    readonly property real handleX: shownFraction * (width - handle.width)
    readonly property real gap: 6

    // Arrastando, segue o dedo; senão (teclado, valor externo), anima.
    Behavior on shownFraction {
        enabled: !root.dragging

        Anim { type: Anim.Standard }
    }

    implicitWidth: 260
    implicitHeight: 36
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4

    function snap(v: real): real {
        const clamped = Math.max(from, Math.min(to, v));
        return stepSize > 0 ? Math.round((clamped - from) / stepSize) * stepSize + from : clamped;
    }

    function setFromX(x: real): void {
        const f = Math.max(0, Math.min(1, (x - handle.width / 2) / (width - handle.width)));
        moved(snap(from + f * (to - from)));
    }

    Keys.onLeftPressed: moved(snap(value - (stepSize || (to - from) / 20)))
    Keys.onRightPressed: moved(snap(value + (stepSize || (to - from) / 20)))

    // Trilho preenchido (à esquerda da alça)
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, root.handleX - root.gap)
        height: 16
        radius: 8
        topRightRadius: 3
        bottomRightRadius: 3
        color: ThemeManager.colors.accent
    }

    // Trilho restante (à direita da alça)
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.handleX + handle.width + root.gap
        width: Math.max(0, root.width - x)
        height: 16
        radius: 8
        topLeftRadius: 3
        bottomLeftRadius: 3
        color: ThemeManager.colors.track

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: 3
            color: ThemeManager.colors.accent
            opacity: 0.7
        }
    }

    Rectangle {
        id: handle

        x: root.handleX
        anchors.verticalCenter: parent.verticalCenter
        width: root.dragging ? 2 : 4
        height: root.dragging ? 40 : 32
        radius: 2
        color: ThemeManager.colors.accent

        Behavior on width { Anim { type: Anim.FastSpatial } }
        Behavior on height { Anim { type: Anim.FastSpatial } }
    }

    // Balão com o valor
    Rectangle {
        readonly property bool shown: root.dragging || root.activeFocus && keyHint.running

        x: root.handleX + handle.width / 2 - width / 2
        y: -height - 6
        width: bubbleText.implicitWidth + 20
        height: 30
        radius: 15
        color: ThemeManager.colors.text
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.6
        transformOrigin: Item.Bottom

        Behavior on opacity { Anim { type: Anim.FastEffects } }
        Behavior on scale { Anim { type: Anim.FastSpatial } }

        Text {
            id: bubbleText

            anchors.centerIn: parent
            text: root.format(root.value)
            color: ThemeManager.colors.base
            font.family: ThemeManager.font.mono
            font.pixelSize: ThemeManager.font.small + 1
            font.weight: Font.DemiBold
        }
    }

    // Mostra o balão por um instante ao mudar pelo teclado.
    Timer {
        id: keyHint

        interval: 900
    }

    onValueChanged: {
        if (activeFocus && !dragging)
            keyHint.restart();
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: event => {
            root.forceActiveFocus();
            root.setFromX(event.x);
        }
        onPositionChanged: event => {
            if (pressed)
                root.setFromX(event.x);
        }
    }
}
