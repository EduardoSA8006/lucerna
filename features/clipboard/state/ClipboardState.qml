pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.config
import qs.core.format
import qs.core.panels
import qs.services

// View model do histórico da área de transferência: busca, filtro (tudo,
// textos, imagens), seleção e colar. Os fixados vêm primeiro. Escolher põe a
// entrada na área de transferência, fecha o painel e, se ligado, cola na
// janela em foco.
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("clipboard")
    readonly property var screen: Hypr.focusedScreen
    readonly property bool enabled: Config.clipboardEnabled
    readonly property bool available: Clipboard.available

    property string query: ""
    property string filter: "all"
    property int selected: 0

    readonly property var filters: [
        { label: "Tudo", value: "all" },
        { label: "Textos", value: "text" },
        { label: "Imagens", value: "image" }
    ]

    readonly property var items: {
        const q = query.trim().toLowerCase();
        const list = Array.from(Clipboard.items).filter(e => (filter === "all" || e.kind === filter) && (!q || (e.kind === "text" && String(e.preview ?? "").toLowerCase().includes(q))));
        return list.filter(e => e.pinned).concat(list.filter(e => !e.pinned));
    }
    readonly property var current: items[Math.min(selected, items.length - 1)] ?? null
    readonly property int count: Clipboard.count

    onItemsChanged: selected = Math.max(0, Math.min(selected, items.length - 1))
    onQueryChanged: selected = 0
    onFilterChanged: selected = 0

    onOpenChanged: {
        if (open) {
            query = "";
            filter = "all";
            selected = 0;
            now = new Date();
        }
    }

    // Relógio para "há 5 min", só enquanto aberto.
    property var now: new Date()

    Timer {
        running: root.open
        repeat: true
        interval: 30000
        onTriggered: root.now = new Date()
    }

    function since(entry: var): string {
        return Format.since(new Date(entry.used), now);
    }

    // Texto de uma linha para a lista (o daemon já junta os espaços).
    function preview(entry: var): string {
        return entry.kind === "image" ? "Imagem" : String(entry.preview ?? "");
    }

    function detail(entry: var): string {
        if (entry.kind === "image")
            return since(entry);
        const lines = entry.lines ?? 1;
        return `${since(entry)} · ${Format.number(entry.size ?? 0, 0)} caracteres${lines > 1 ? ` · ${lines} linhas` : ""}`;
    }

    function move(step: int): void {
        if (items.length)
            selected = (selected + step + items.length) % items.length;
    }

    function select(index: int): void {
        selected = index;
    }

    function activate(entry: var): void {
        if (!entry)
            return;
        Clipboard.copy(entry.id);
        Panels.close();
        if (Config.clipboardPaste)
            Clipboard.paste();
    }

    function remove(entry: var): void {
        if (entry)
            Clipboard.remove(entry.id);
    }

    function togglePin(entry: var): void {
        if (entry)
            Clipboard.pin(entry.id, !entry.pinned);
    }

    // Tira tudo menos os fixados.
    function clear(): void {
        Clipboard.clear(false);
    }

    function close(): void {
        Panels.dismiss("clipboard");
    }

    function openSettings(): void {
        Config.settingsTopic = "clipboard";
        Panels.open("settings");
    }

    // Nesta ordem: o limite e a persistência chegam ao daemon (configure)
    // antes da assinatura do histórico.
    Binding {
        target: Clipboard
        property: "limit"
        value: Config.clipboardLimit
    }

    Binding {
        target: Clipboard
        property: "persist"
        value: Config.clipboardPersist
    }

    Binding {
        target: Clipboard
        property: "watching"
        value: Config.clipboardEnabled
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            Panels.toggle("clipboard");
        }

        function open(): void {
            Panels.open("clipboard");
        }

        // Tira tudo menos os fixados.
        function clear(): void {
            root.clear();
        }

        function count(): int {
            return root.count;
        }
    }
}
