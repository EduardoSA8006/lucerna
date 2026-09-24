import QtQuick
import qs.core.theme

// Um wallpaper animado (shader .qsb de themes/shaders). Os uniforms são os
// mesmos para todos: time, resolution e as cores base, surface, accent e text.
// O tempo avança por um Timer na taxa pedida (e não na do monitor), e só
// enquanto `running`: parado, nada redesenha e o último quadro fica.
ShaderEffect {
    id: root

    property string shader
    property bool running: true
    property int fps: 30

    // Cores: as do tema ativo, ou as de outro tema (prévias).
    property color base: ThemeManager.colors.base
    property color surface: ThemeManager.colors.surface
    property color accent: ThemeManager.colors.accent
    property color text: ThemeManager.colors.text

    property real time: 0
    readonly property vector2d resolution: Qt.vector2d(width, height)
    readonly property bool ready: status === ShaderEffect.Compiled && shader !== ""
    readonly property bool failed: status === ShaderEffect.Error

    // Textura de ruído dos efeitos (themes/shaders/noise.png), repetida.
    property var noiseTex: ShaderEffectSource {
        wrapMode: ShaderEffectSource.Repeat
        hideSource: true
        sourceItem: Image {
            source: `file://${ThemeManager.directory}/shaders/noise.png`
            width: 256
            height: 256
            smooth: true
        }
    }

    fragmentShader: shader ? `file://${shader}` : ""
    blending: false

    Timer {
        interval: Math.round(1000 / Math.max(1, root.fps))
        repeat: true
        running: root.running && root.visible && !root.failed
        onTriggered: root.time += interval / 1000
    }
}
