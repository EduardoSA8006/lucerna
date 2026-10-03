pragma ComponentBehavior: Bound

import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.central.state

// Central: dois painéis flutuantes na direita, sobre a área de trabalho, sem
// escurecer a tela, que abrem e fecham juntos: as ações em cima (na altura do
// conteúdo, até deixar o mínimo das notificações) e as notificações embaixo,
// na altura que sobra. Cada painel entra deslizando da direita, em cascata; a
// saída é dos dois juntos, mais rápida. Esc ou o clique fora dos painéis
// fecham.
OverlayPanel {
    id: panel

    name: "central"
    open: CentralState.open
    screen: CentralState.screen
    dim: 0
    // A barra continua clicável: o mesmo ícone fecha, outro troca a entrada.
    keepBar: true
    onDismissed: CentralState.close()

    // Distância das bordas da tela e entre os dois painéis.
    readonly property real margin: ThemeManager.spacing.large
    readonly property real gap: ThemeManager.spacing.normal
    // Altura mínima das notificações.
    readonly property real inboxMin: 160
    // Os painéis, para a entrada e a saída.
    readonly property var panels: [actions, inbox]

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

    ActionsPanel {
        id: actions

        order: 0
        margin: panel.margin
        areaWidth: panel.width
        y: CentralState.top
        maxHeight: Math.max(0, panel.height - y - panel.margin - panel.gap - panel.inboxMin)
    }

    InboxPanel {
        id: inbox

        order: 1
        margin: panel.margin
        areaWidth: panel.width
        y: actions.y + actions.height + panel.gap
        height: Math.max(0, panel.height - y - panel.margin)
    }
}
