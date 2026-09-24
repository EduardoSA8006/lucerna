import QtQuick
import qs.core.theme
import qs.core.widgets

// Um papel de parede para escolher: a imagem e, se houver, o efeito por cima,
// nas cores do tema. O efeito só anda com o mouse em cima ou quando é o
// escolhido; no resto do tempo fica parado (sem custo).
Clickable {
    id: root

    property string image
    property string shader
    property var colors: ({})
    property string label
    property string detail
    property bool selected: false

    implicitHeight: width * 9 / 16 + 44
    radius: ThemeManager.radius.normal + 2
    pressScale: 0.96
    color: selected ? ThemeManager.alpha(ThemeManager.colors.accent, 0.14) : ThemeManager.alpha(ThemeManager.colors.text, 0.04)
    border.width: selected ? 2 : 0
    border.color: ThemeManager.colors.accent

    Rectangle {
        id: frame

        x: 6
        y: 6
        width: parent.width - 12
        height: width * 9 / 16
        radius: ThemeManager.radius.small + 2
        color: root.colors.base ?? ThemeManager.colors.base
        clip: true

        Image {
            anchors.fill: parent
            source: root.image ? `file://${root.image}` : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(320, 180)
            asynchronous: true
        }

        // Entra aparecendo. Não dá para esperar o shader compilar com ele
        // invisível: o Qt não desenha item com opacidade 0, e sem desenhar
        // ele não compila.
        Loader {
            id: preview

            anchors.fill: parent
            active: root.shader !== ""
            opacity: 0
            onLoaded: previewFade.restart()

            Anim {
                id: previewFade

                target: preview
                property: "opacity"
                to: 1
                type: Anim.Effects
            }

            sourceComponent: EffectView {
                shader: root.shader
                fps: 24
                running: root.hovered || root.selected
                // Prévia começa num ponto já "andado" do efeito.
                time: 20
                base: root.colors.base ?? ThemeManager.colors.base
                surface: root.colors.surface ?? ThemeManager.colors.surface
                accent: root.colors.accent ?? ThemeManager.colors.accent
                text: root.colors.text ?? ThemeManager.colors.text
            }
        }

        Rectangle {
            visible: root.shader !== ""
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6
            width: badge.implicitWidth + 12
            height: 20
            radius: 10
            color: ThemeManager.alpha("#000000", 0.45)

            Txt {
                id: badge

                anchors.centerIn: parent
                text: "Animado"
                color: "#ffffff"
                font.pixelSize: ThemeManager.font.small - 1
            }
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: frame.bottom
        anchors.margins: 8
        anchors.topMargin: 6
        spacing: 0

        Txt {
            width: parent.width
            text: root.label
            elide: Text.ElideRight
            font.weight: root.selected ? Font.DemiBold : Font.Normal
            color: root.selected ? ThemeManager.colors.accent : ThemeManager.colors.text
            font.pixelSize: ThemeManager.font.small + 1
        }

        Txt {
            width: parent.width
            text: root.detail
            elide: Text.ElideRight
            faint: true
            font.pixelSize: ThemeManager.font.small - 1
        }
    }
}
