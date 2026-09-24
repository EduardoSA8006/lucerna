import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.theme
import qs.core.widgets
import qs.features.wallpaper.state

// O papel de parede de um monitor, na camada de fundo: a imagem por baixo e,
// se houver, o efeito animado por cima. A imagem aparece primeiro; o efeito
// surge quando o shader fica pronto, então nunca há tela vazia.
PanelWindow {
    id: window

    required property var targetScreen
    readonly property var wallpaper: WallpaperState.source(targetScreen)
    readonly property bool effect: WallpaperState.showsEffect(targetScreen)

    screen: targetScreen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: ThemeManager.colors.base
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "lucerna-wallpaper"

    StaticWallpaper {
        anchors.fill: parent
        source: window.wallpaper.static
        fillMode: window.wallpaper.kind === "image" ? WallpaperState.fill : Image.PreserveAspectCrop
        fadeDuration: WallpaperState.fadeDuration
    }

    // Em meia resolução (ampliado): para névoa, brilho e chama a diferença é
    // mínima e o custo cai para um quarto.
    Loader {
        id: effectLoader

        readonly property real factor: WallpaperState.fullRes ? 1 : 0.5

        active: window.effect
        width: parent.width * factor
        height: parent.height * factor
        scale: 1 / factor
        transformOrigin: Item.TopLeft
        // Entra aparecendo por cima da imagem (não dá para esperar o shader
        // compilar invisível: o Qt não desenha item com opacidade 0).
        opacity: 0
        onLoaded: fadeIn.restart()

        NumberAnimation {
            id: fadeIn

            target: effectLoader
            property: "opacity"
            to: 1
            duration: WallpaperState.fadeDuration
        }

        sourceComponent: EffectView {
            shader: window.wallpaper.shader
            fps: Math.min(WallpaperState.fps, window.wallpaper.fps ?? 30)
            running: WallpaperState.shouldAnimate(window.targetScreen)
        }
    }
}
