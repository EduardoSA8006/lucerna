pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.core.carousel
import qs.core.theme
import qs.core.widgets

// Um tema na fila do seletor: o papel de parede estático (com a escolha do
// usuário para aquele tema), o nome e três amostras de cor, nas cores do
// próprio tema. `distance` é quantos passos o card está do centro, com sinal:
// cada passo encolhe 20%, apaga e deixa mais transparente; depois do
// terceiro, some. O central ganha a borda na cor de destaque do tema ativo.
Item {
    id: card

    required property var theme
    required property int distance
    // Centro horizontal da fila, na tela.
    required property real centerX
    // Entrada e saída (0 → 1), animadas por enter() e leave().
    property real shown: 0
    readonly property var c: theme.colors ?? ({})
    readonly property int reach: Math.abs(distance)
    readonly property string still: ThemeManager.wallpaperFor(theme.id).static
    // Quanto o card apaga: 0 no centro, 1 no terceiro passo.
    property real dimness: Math.min(reach, 3) / 3
    // A distância anterior, e se o último giro foi de um passo (desliza) ou
    // um pulo de um lado da fila para o outro (na volta de fila curta).
    property int last: 0
    property bool sliding: true

    signal clicked

    width: 320
    height: 180
    z: -reach
    scale: Math.pow(0.8, reach)
    opacity: Math.min(1, shown)
    visible: shown > 0 && effect.opacity > 0
    // Sobe da borda de baixo na entrada e desce na saída.
    transform: Translate { y: (1 - card.shown) * 240 }

    // O x é posto aqui, não por binding: o pulo é decidido antes de o x mudar.
    onDistanceChanged: {
        sliding = Math.abs(distance - last) <= 1;
        last = distance;
        place();
    }
    onCenterXChanged: place()
    Component.onCompleted: {
        last = distance;
        place();
    }

    // Sem animar enquanto escondido (ao abrir, a fila já está no lugar) nem no pulo.
    Behavior on x { enabled: card.shown > 0 && card.sliding; Anim { type: Anim.Spatial } }
    Behavior on scale { enabled: card.shown > 0; Anim { type: Anim.Spatial } }
    Behavior on dimness { enabled: card.shown > 0; Anim { type: Anim.Effects } }

    function place(): void {
        x = centerX + Carousel.spread(distance, width, ThemeManager.spacing.large, 0.8) - width / 2;
    }

    function enter(): void {
        leaving.stop();
        shown = 0;
        entering.restart();
    }

    function leave(): void {
        entering.stop();
        leaving.restart();
    }

    // Cascata do centro para fora: 40 ms por passo, na escala de animação.
    SequentialAnimation {
        id: entering

        PauseAnimation { duration: card.reach * 40 * ThemeManager.anim.scale }
        Anim { target: card; property: "shown"; to: 1; type: Anim.Spatial }
    }

    Anim {
        id: leaving

        target: card
        property: "shown"
        to: 0
        type: Anim.StandardAccel
    }

    Item {
        id: body

        anchors.fill: parent
        visible: false
        layer.enabled: true

        ClippingRectangle {
            anchors.fill: parent
            radius: ThemeManager.radius.large
            color: card.c.base ?? "black"
            border.width: ThemeManager.outlines ? 1 : 0
            border.color: card.c.border ?? "gray"

            Image {
                anchors.fill: parent
                source: card.still ? `file://${card.still}` : ""
                sourceSize: Qt.size(640, 360)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            // Véu na base do card, para o nome e as cores lerem sobre o papel.
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 64
                gradient: Gradient {
                    GradientStop { position: 0; color: ThemeManager.alpha(card.c.base ?? "black", 0) }
                    GradientStop { position: 1; color: ThemeManager.alpha(card.c.base ?? "black", 0.85) }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: ThemeManager.spacing.normal
                text: card.theme.name
                color: card.c.text ?? "white"
                font.family: ThemeManager.font.sans
                font.pixelSize: ThemeManager.font.normal
                font.weight: Font.DemiBold
            }

            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: ThemeManager.spacing.normal
                anchors.bottomMargin: ThemeManager.spacing.normal + 2
                spacing: 4

                Repeater {
                    model: ["raised", "text", "accent"]

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

        // Borda do card central, por cima do papel de parede.
        Rectangle {
            anchors.fill: parent
            radius: ThemeManager.radius.large
            color: "transparent"
            border.width: 2
            border.color: ThemeManager.colors.accent
            opacity: card.reach === 0 ? 1 : 0

            Behavior on opacity { Anim { type: Anim.Effects } }
        }
    }

    // Apagado (saturação e brilho), transparência e sombra.
    MultiEffect {
        id: effect

        anchors.fill: body
        source: body
        opacity: card.reach > 3 ? 0 : 1 - 0.6 * card.dimness
        saturation: -0.7 * card.dimness
        brightness: -0.35 * card.dimness
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.35
        shadowBlur: 0.8
        shadowVerticalOffset: 6

        Behavior on opacity { enabled: card.shown > 0; Anim { type: Anim.Effects } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked()
    }
}
