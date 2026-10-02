pragma ComponentBehavior: Bound

import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.central.state

// Central: painéis flutuantes sobre a área de trabalho, sem escurecer a tela,
// que abrem e fecham juntos. À direita, as notificações, na altura que sobra.
// Cada painel entra deslizando do seu lado, em cascata; a saída é de todos
// juntos, mais rápida. Esc ou o clique fora de todos os painéis fecham; a
// barra fica fora da camada e continua clicável.
OverlayPanel {
    id: panel

    name: "central"
    open: CentralState.open
    screen: CentralState.screen
    dim: 0
    // A barra continua clicável: o mesmo ícone fecha, outro troca a entrada.
    keepBar: true
    onDismissed: CentralState.close()

    // Distância das bordas da tela e entre os dois painéis de uma coluna.
    readonly property real margin: ThemeManager.spacing.large
    readonly property real gap: ThemeManager.spacing.normal
    // Os painéis, para a entrada e a saída.
    readonly property var panels: [inbox]

    onOpenChanged: {
        for (const p of panels) {
            if (open)
                p.enter();
            else
                p.leave();
        }
        if (open)
            focusSink.forceActiveFocus();
    }

    // Fica com o teclado ao abrir: o Esc sobe dele até o OverlayPanel. Sem
    // tamanho, não segura o clique fora.
    Item {
        id: focusSink
    }

    InboxPanel {
        id: inbox

        leftSide: false
        order: 3
        margin: panel.margin
        areaWidth: panel.width
        y: CentralState.top
        height: Math.max(0, panel.height - y - panel.margin)
    }
}
