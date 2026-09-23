import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.theme

// Janela de sobreposição em tela cheia para painéis (launcher, temas, energia,
// central de notificações). Escurece o fundo, pega o teclado enquanto aberta e
// avisa `dismissed` ao clicar fora do conteúdo ou apertar Esc.
//
// O conteúdo vai como filho direto; `progress` (0 → 1) acompanha a animação de
// abertura para o conteúdo animar junto.
PanelWindow {
    id: root

    required property bool open
    property real dim: 0.45
    property string name: "panel"
    readonly property real progress: shown
    default property alias content: container.data

    signal dismissed

    property real shown: open ? 1 : 0

    Behavior on shown {
        NumberAnimation {
            duration: ThemeManager.anim.normal
            easing.type: Easing.OutCubic
        }
    }

    visible: shown > 0
    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: `lucerna-${name}`
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: ThemeManager.alpha("#000000", root.dim * root.shown)
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: event => {
            if (!container.childAt(event.x, event.y))
                root.dismissed();
        }
    }

    FocusScope {
        id: container

        anchors.fill: parent
        opacity: root.shown
        focus: true
        Keys.onEscapePressed: root.dismissed()
    }
}
