import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.theme
import qs.core.widgets
import qs.features.bar.state

// A janela da barra num monitor. O arranjo vem do estilo escolhido nas
// configurações (faixa, ilha, pílula ou três ilhas); todos seguem as mesmas
// regras de aparecer e esconder, e só as partes visíveis recebem o mouse.
PanelWindow {
    id: root

    // A tela vem de fora (fixa por janela). Ler `screen` da própria janela aqui
    // daria laço: mudar a visibilidade renotifica `screen`.
    required property var targetScreen
    readonly property bool shown: BarState.shownOn(targetScreen)
    readonly property bool strip: BarState.style === "strip"
    property real progress: shown ? 1 : 0

    Behavior on progress {
        Anim {
            type: root.shown ? Anim.Spatial : Anim.EmphasizedAccel
        }
    }

    screen: targetScreen
    visible: shown || progress > 0
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: strip ? ThemeManager.barHeight : ThemeManager.barHeight + ThemeManager.spacing.small * 2
    color: "transparent"
    exclusionMode: BarState.autoHide ? ExclusionMode.Ignore : ExclusionMode.Auto
    mask: layout.item?.mask ?? null
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "lucerna-panel-bar"

    Loader {
        id: layout

        anchors.fill: parent
        sourceComponent: ({
            strip: stripLayout,
            island: islandLayout,
            pill: pillLayout,
            islands: islandsLayout
        })[BarState.style] ?? stripLayout
    }

    Component {
        id: stripLayout

        StripLayout {
            progress: root.progress
        }
    }

    Component {
        id: islandLayout

        IslandLayout {
            progress: root.progress
        }
    }

    Component {
        id: pillLayout

        PillLayout {
            progress: root.progress
        }
    }

    Component {
        id: islandsLayout

        IslandsLayout {
            progress: root.progress
        }
    }
}
