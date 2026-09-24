pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.core.launcher

// View model de Configurações → Launcher: estilo, buscador da web, favoritos,
// apps ocultos e o histórico de uso (que ordena os apps).
Singleton {
    id: root

    readonly property var styles: [
        { id: "compact", label: "Compacto", hint: "Busca e uma lista curta" },
        { id: "full", label: "Completo", hint: "Categorias, grade e detalhes" },
        { id: "grid", label: "Tela cheia", hint: "Gaveta de apps, por categoria" }
    ]
    readonly property string style: Config.launcherStyle

    function setStyle(id: string): void {
        Config.launcherStyle = id;
    }

    readonly property var engineOptions: SearchEngines.all.map(e => ({ label: e.name, value: e.id }))
    readonly property string engine: Config.launcherSearchEngine

    function setEngine(id: string): void {
        Config.launcherSearchEngine = id;
    }

    function entry(id: string): var {
        return DesktopEntries.applications.values.find(a => a.id === id) ?? null;
    }

    // Favoritos e ocultos, com nome e ícone (os que ainda existem).
    readonly property var favorites: (Config.launcherFavorites ?? []).map(entry).filter(e => e)
    readonly property var hidden: (Config.launcherHidden ?? []).map(entry).filter(e => e)
    readonly property int usedCount: Object.keys(Config.launcherUsage ?? {}).length

    function unpin(id: string): void {
        Config.launcherFavorites = (Config.launcherFavorites ?? []).filter(f => f !== id);
    }

    function moveFavorite(id: string, step: int): void {
        const list = (Config.launcherFavorites ?? []).slice();
        const i = list.indexOf(id);
        const j = i + step;
        if (i < 0 || j < 0 || j >= list.length)
            return;
        [list[i], list[j]] = [list[j], list[i]];
        Config.launcherFavorites = list;
    }

    function unhide(id: string): void {
        Config.launcherHidden = (Config.launcherHidden ?? []).filter(h => h !== id);
    }

    function clearUsage(): void {
        Config.launcherUsage = {};
    }
}
