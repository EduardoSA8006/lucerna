import QtQuick
import qs.core.theme
import qs.core.widgets

// Um dos quatro painéis da central: o vidro dos painéis do shell, 400 px de
// largura, colado na borda do seu lado (`leftSide`) a `margin` dela. Entra
// deslizando desse lado, com um atraso pela ordem (`order`: 40 ms por passo,
// na escala das animações), e sai junto com os outros, mais rápido.
// `present` falso esconde o painel (nada a mostrar). Os filhos vão para
// dentro da margem interna (`padding`).
Surface {
    id: root

    required property bool leftSide
    required property int order
    required property real margin
    // Largura da tela, para colar na borda direita.
    required property real areaWidth
    property bool present: true
    // Entrada e saída (0 → 1), animadas por enter() e leave().
    property real shown: 0
    readonly property real padding: ThemeManager.spacing.normal
    readonly property real travel: width + margin + 24
    default property alias content: body.data

    level: 0
    width: 400
    radius: ThemeManager.radius.large
    visible: present && shown > 0
    opacity: Math.min(1, shown)
    x: leftSide ? margin - (1 - shown) * travel : areaWidth - width - margin + (1 - shown) * travel

    function enter(): void {
        // Reaberta na saída, segue de onde está; senão, entra do zero.
        if (leaving.running)
            leaving.stop();
        else
            shown = 0;
        entering.restart();
    }

    function leave(): void {
        entering.stop();
        leaving.restart();
    }

    SequentialAnimation {
        id: entering

        PauseAnimation { duration: root.order * 40 * ThemeManager.anim.scale }
        Anim { target: root; property: "shown"; to: 1; type: Anim.Spatial }
    }

    Anim {
        id: leaving

        target: root
        property: "shown"
        to: 0
        type: Anim.StandardAccel
    }

    Item {
        id: body

        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        height: root.height - root.padding * 2
    }
}
