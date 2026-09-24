pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Informações de um app que o .desktop não traz (versão, desenvolvedor, resumo,
// site), do pacote e do AppStream (scripts/app-info.sh). Pedidas só para o app
// que se está olhando, uma de cada vez, e guardadas em cache.
Singleton {
    id: root

    // id → { version, developer, summary, url, package }
    property var cache: ({})
    property var queue: []
    property string current: ""

    function info(id: string): var {
        return cache[id] ?? null;
    }

    function request(id: string): void {
        if (!id || id in cache || id === current || queue.includes(id))
            return;
        queue = queue.concat([id]);
        next();
    }

    function next(): void {
        if (current || !queue.length)
            return;
        current = queue[0];
        queue = queue.slice(1);
        reader.command = [Quickshell.shellPath("services/scripts/app-info.sh"), current];
        reader.running = true;
    }

    function decodeEntities(text: string): string {
        return text.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&#39;|&apos;/g, "'").replace(/&amp;/g, "&");
    }

    Process {
        id: reader

        stdout: StdioCollector {
            onStreamFinished: {
                const info = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        info[line.slice(0, i)] = root.decodeEntities(line.slice(i + 1).trim());
                }
                const all = Object.assign({}, root.cache);
                all[root.current] = info;
                root.cache = all;
                root.current = "";
                Qt.callLater(root.next);
            }
        }
    }
}
