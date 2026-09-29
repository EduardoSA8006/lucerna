pragma ComponentBehavior: Bound
import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.launcher.state

// Launcher em três estilos (Configurações → Launcher): compacto (busca e
// lista), completo (categorias, grade e detalhes) e tela cheia (gaveta de
// apps). Todos usam o mesmo estado; Esc ou clique fora fecham.
OverlayPanel {
    id: panel

    name: "launcher"
    open: LauncherState.open
    screen: LauncherState.screen
    // A tela cheia já cobre tudo com vidro.
    dim: LauncherState.style === "grid" ? 0 : ThemeManager.dark ? 0.4 : 0.22
    onDismissed: LauncherState.close()

    // O item do Loader é um QObject: o `as` de cada estilo dá o tipo que tem focusSearch.
    function focusSearch(): void {
        const item = style.item;
        (item as CompactLauncher)?.focusSearch();
        (item as FullLauncher)?.focusSearch();
        (item as GridLauncher)?.focusSearch();
    }

    onOpenChanged: {
        if (open)
            Qt.callLater(() => panel.focusSearch());
    }

    Loader {
        id: style

        anchors.fill: parent
        sourceComponent: ({ compact: compact, full: full, grid: grid })[LauncherState.style] ?? compact
        onLoaded: {
            if (panel.open)
                panel.focusSearch();
        }
    }

    Component {
        id: compact

        CompactLauncher {
            progress: panel.progress
        }
    }

    Component {
        id: full

        FullLauncher {
            progress: panel.progress
        }
    }

    Component {
        id: grid

        GridLauncher {
            progress: panel.progress
        }
    }
}
