pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Histórico da área de transferência, pelo wl-clipboard: o `wl-paste --watch`
// avisa cada mudança (texto ou imagem PNG; senhas marcadas pelos
// gerenciadores ficam de fora) e o histórico guarda os últimos `limit`, com os
// fixados à parte. Com `persist`, sobrevive a reinícios (em statePath).
// Entrada: { id, kind: "text" | "image", text?, path?, md5?, time (ms), pinned }.
Singleton {
    id: root

    // Quem usa decide.
    property bool watching: false
    property int limit: 100
    property bool persist: true

    property var entries: []
    property bool available: false

    readonly property string imageDir: Quickshell.statePath("clipboard")
    readonly property string historyFile: Quickshell.statePath("clipboard.json")
    readonly property string script: Quickshell.shellPath("services/scripts/clipboard-watch.sh")

    // Base64 → texto UTF-8 (o Qt.atob de texto é obsoleto e não decodifica UTF-8).
    function decode(b64: string): string {
        const table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        const bytes = [];
        let buffer = 0;
        let bits = 0;
        for (const ch of b64) {
            const v = table.indexOf(ch);
            if (v < 0)
                continue;
            buffer = (buffer << 6) | v;
            bits += 6;
            if (bits >= 8) {
                bits -= 8;
                bytes.push((buffer >> bits) & 0xff);
            }
        }
        let out = "";
        for (let i = 0; i < bytes.length;) {
            const b = bytes[i];
            const n = b >= 0xf0 ? 3 : b >= 0xe0 ? 2 : b >= 0xc0 ? 1 : 0;
            let code = n ? b & (0x3f >> n) : b;
            for (let k = 1; k <= n; k++)
                code = (code << 6) | ((bytes[i + k] ?? 0) & 0x3f);
            out += String.fromCodePoint(code);
            i += n + 1;
        }
        return out;
    }

    function makeId(): string {
        return `${Date.now().toString(36)}${Math.floor(Math.random() * 1e6).toString(36)}`;
    }

    function add(entry: var): void {
        const same = entries.find(e => e.kind === entry.kind && (entry.kind === "text" ? e.text === entry.text : e.md5 === entry.md5));
        if (same) {
            // Já estava: sobe para o topo, e a imagem repetida sai do disco.
            if (entry.kind === "image" && entry.path !== same.path)
                Quickshell.execDetached(["rm", "-f", entry.path]);
            entries = [Object.assign({}, same, { time: Date.now() })].concat(entries.filter(e => e.id !== same.id));
        } else {
            entries = [Object.assign({ id: makeId(), time: Date.now(), pinned: false }, entry)].concat(entries);
        }
        trim();
        modified();
    }

    // Passou do limite: saem os mais antigos que não estão fixados.
    function trim(): void {
        let loose = entries.filter(e => !e.pinned).length;
        if (loose <= limit)
            return;
        const out = [];
        for (let i = entries.length - 1; i >= 0; i--) {
            const e = entries[i];
            if (!e.pinned && loose > limit) {
                loose--;
                forget(e);
            } else {
                out.unshift(e);
            }
        }
        entries = out;
    }

    function forget(entry: var): void {
        if (entry.kind === "image" && entry.path)
            Quickshell.execDetached(["rm", "-f", entry.path]);
    }

    function remove(id: string): void {
        const entry = entries.find(e => e.id === id);
        if (!entry)
            return;
        forget(entry);
        entries = entries.filter(e => e.id !== id);
        modified();
    }

    function togglePin(id: string): void {
        entries = entries.map(e => e.id === id ? Object.assign({}, e, { pinned: !e.pinned }) : e);
        modified();
    }

    // Limpa o histórico; `all` leva junto os fixados.
    function clear(all: bool): void {
        for (const e of entries) {
            if (all || !e.pinned)
                forget(e);
        }
        entries = all ? [] : entries.filter(e => e.pinned);
        modified();
    }

    // Põe uma entrada na área de transferência (o watcher a sobe para o topo).
    function copy(entry: var): void {
        if (entry.kind === "image") {
            Quickshell.execDetached(["sh", "-c", 'wl-copy --type image/png < "$1"', "sh", entry.path]);
        } else {
            copier.pending = entry.text;
            copier.running = false;
            copier.running = true;
        }
    }

    // Cola na janela em foco: Ctrl+V, ou Ctrl+Shift+V num terminal. Com um
    // atraso, para o painel fechar e o foco voltar para a janela.
    function paste(): void {
        pasteDelay.restart();
    }

    readonly property var terminals: ["kitty", "foot", "footclient", "alacritty", "org.wezfurlong.wezterm", "com.mitchellh.ghostty", "org.kde.konsole", "konsole", "org.gnome.terminal", "gnome-terminal-server", "org.gnome.ptyxis", "xterm", "st-256color", "tilix", "terminator"]

    Timer {
        id: pasteDelay

        interval: 180
        onTriggered: activeWindow.running = true
    }

    Process {
        id: activeWindow

        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let cls = "";
                try {
                    cls = String(JSON.parse(text).class ?? "").toLowerCase();
                } catch (e) {}
                const mods = root.terminals.includes(cls) ? "CTRL SHIFT" : "CTRL";
                Hypr.dispatch(`hl.dsp.send_shortcut({ mods = "${mods}", key = "V" })`);
            }
        }
    }

    // O texto vai pela entrada padrão (um argumento tem limite de tamanho).
    Process {
        id: copier

        property string pending: ""

        command: ["wl-copy"]
        stdinEnabled: true
        onStarted: {
            write(pending);
            stdinEnabled = false;
        }
        onExited: stdinEnabled = true
    }

    // Persistência. Quem usa chama `start()` depois de definir `persist`: com
    // ele, o histórico salvo volta; sem ele, o salvo (e as imagens) é apagado.
    signal modified()

    property bool started: false

    function start(): void {
        if (started)
            return;
        started = true;
        if (persist)
            store.path = historyFile;
        else
            Quickshell.execDetached(["sh", "-c", 'rm -f "$1"; rm -rf "$2"', "sh", historyFile, imageDir]);
    }

    onModified: saveDelay.restart()

    Timer {
        id: saveDelay

        interval: 800
        onTriggered: {
            if (root.persist && store.path)
                store.setText(JSON.stringify(root.entries));
        }
    }

    // Deixar de manter apaga o arquivo (o que está na memória fica até sair).
    onPersistChanged: {
        if (!started)
            return;
        if (persist) {
            store.path = historyFile;
            saveDelay.restart();
        } else {
            store.path = "";
            Quickshell.execDetached(["rm", "-f", historyFile]);
        }
    }

    FileView {
        id: store

        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                const list = JSON.parse(text());
                if (Array.isArray(list) && !root.entries.length)
                    root.entries = list.filter(e => e && (e.kind === "text" ? typeof e.text === "string" : !!e.path));
            } catch (e) {}
        }
    }

    // Tem o wl-clipboard?
    Process {
        running: true
        command: ["sh", "-c", "command -v wl-paste && command -v wl-copy"]
        onExited: code => root.available = code === 0
    }

    Process {
        id: watcher

        running: root.watching && root.available
        // O pdeathsig faz o wl-paste sair junto com o shell (senão ele fica
        // órfão num reinício e continua gravando imagens).
        command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--watch", root.script, root.imageDir]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split("\t");
                if (parts[0] === "text" && parts[1])
                    root.add({ kind: "text", text: root.decode(parts[1]) });
                else if (parts[0] === "image" && parts[1])
                    root.add({ kind: "image", path: parts[1], md5: parts[2] ?? "" });
            }
        }
    }
}
