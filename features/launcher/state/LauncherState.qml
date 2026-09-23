pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.core.panels
import qs.core.widgets
import qs.services

// View model do launcher: busca em aplicativos e ações rápidas.
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("launcher")
    readonly property var screen: Hypr.focusedScreen
    property string query: ""
    readonly property int maxResults: 8

    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)

    // Ações do próprio shell. `keywords` ajuda a achar por sinônimos.
    readonly property var actions: [
        { name: "Bloquear tela", description: "Ação", glyph: Icons.lock, keywords: "lock bloqueio", run: () => Session.lock() },
        { name: "Painel", description: "Ação", glyph: Icons.dashboard, keywords: "dashboard calendario clima desempenho midia musica", run: () => Panels.open("dashboard") },
        { name: "Trocar tema", description: "Ação", glyph: Icons.palette, keywords: "theme cores aparência", run: () => Panels.open("themes") },
        { name: "Notificações", description: "Ação", glyph: Icons.bell, keywords: "central avisos", run: () => Panels.open("notifications") },
        { name: Config.doNotDisturb ? "Desativar não perturbe" : "Ativar não perturbe", description: "Ação", glyph: Icons.bellSleep, keywords: "dnd silencio silenciar", run: () => Config.doNotDisturb = !Config.doNotDisturb },
        { name: "Menu de energia", description: "Ação", glyph: Icons.power, keywords: "desligar reiniciar suspender sair logout power", run: () => Panels.open("power") }
    ]

    readonly property var results: search(query)

    onOpenChanged: {
        if (open)
            query = "";
    }

    function close(): void {
        Panels.close();
    }

    function activate(result: var): void {
        if (!result)
            return;
        Panels.close();
        if (result.entry)
            result.entry.execute();
        else
            result.run();
    }

    function normalize(text: string): string {
        return (text ?? "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
    }

    // Pontua um texto contra a busca: começo do nome > começo de palavra >
    // trecho > letras na ordem (subsequência).
    function score(q: string, name: string, extra: string): int {
        const n = normalize(name);
        if (n.startsWith(q))
            return 100;
        if (n.split(/[\s\-_.]+/).some(word => word.startsWith(q)))
            return 80;
        if (n.includes(q))
            return 60;
        if (normalize(extra).includes(q))
            return 30;
        let i = 0;
        for (const ch of n)
            if (ch === q[i])
                i++;
        return i === q.length ? 10 : 0;
    }

    function search(text: string): var {
        const q = normalize(text.trim());
        const fromApp = entry => ({
            name: entry.name,
            description: entry.genericName || entry.comment || "",
            icon: entry.icon,
            glyph: Icons.application,
            entry: entry
        });

        if (!q)
            return apps.slice().sort((a, b) => a.name.localeCompare(b.name)).slice(0, maxResults).map(fromApp);

        const scored = [];
        for (const entry of apps) {
            const s = score(q, entry.name, `${entry.genericName} ${entry.keywords} ${entry.comment} ${entry.id}`);
            if (s > 0)
                scored.push({ s: s, r: fromApp(entry) });
        }
        for (const action of actions) {
            const s = score(q, action.name, action.keywords);
            if (s > 0)
                scored.push({ s: s - 1, r: action });
        }
        scored.sort((a, b) => b.s - a.s || a.r.name.localeCompare(b.r.name));
        return scored.slice(0, maxResults).map(x => x.r);
    }
}
