import QtQuick
import qs.core.theme
import qs.core.widgets

// Um dos dois painéis da central: o vidro dos painéis do shell, `panelWidth`
// de largura, colado na borda direita a `margin` dela. Entra deslizando da
// direita e sai, mais rápido, pelo mesmo caminho. Com os dois abrindo juntos,
// a entrada vai em cascata, com um atraso pela ordem (`order`: 40 ms por
// passo, na escala das animações). Os filhos vão para dentro da margem
// interna (`padding`).
Surface {
    id: root

    required property int order
    required property real margin
    // Largura da tela, para colar na borda direita.
    required property real areaWidth
    property real panelWidth: 440
    // Entrada e saída (0 → 1), animadas por enter() e leave().
    property real shown: 0
    // Pedido aberto (o último enter() ou leave()).
    property bool wanted: false
    // A entrada atual espera a vez da ordem (os dois abrindo juntos).
    property bool cascade: false
    readonly property real padding: ThemeManager.spacing.normal
    readonly property real travel: width + margin + 24
    default property alias content: body.data

    level: 0
    width: panelWidth
    radius: ThemeManager.radius.large
    visible: shown > 0
    opacity: Math.min(1, shown)
    x: areaWidth - width - margin + (1 - shown) * travel

    function enter(cascade: bool): void {
        wanted = true;
        root.cascade = cascade;
        // Reaberta na saída, segue de onde está; senão, entra do zero.
        if (leaving.running)
            leaving.stop();
        else
            shown = 0;
        entering.restart();
    }

    function leave(): void {
        wanted = false;
        entering.stop();
        leaving.restart();
    }

    SequentialAnimation {
        id: entering

        PauseAnimation { duration: root.cascade ? root.order * 40 * ThemeManager.anim.scale : 0 }
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
