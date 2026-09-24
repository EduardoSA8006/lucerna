pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Busca de arquivos na pasta pessoal para o launcher (scripts/file-search.sh):
// por tipo (all, documents, images, music, videos) e nome; sem nome, os
// recentes. Uma busca nova cancela a anterior, e digitar rápido vira uma só.
Singleton {
    id: root

    // [{ path, name, dir, size, modified }]
    property var results: []
    property bool searching: false
    property string kind: "all"
    property string query: ""

    function search(kind: string, query: string): void {
        root.kind = kind;
        root.query = query;
        searching = true;
        debounce.restart();
    }

    Timer {
        id: debounce

        interval: 140
        onTriggered: {
            runner.running = false;
            runner.command = [Quickshell.shellPath("services/scripts/file-search.sh"), root.kind, root.query, "60"];
            Qt.callLater(() => runner.running = true);
        }
    }

    Process {
        id: runner

        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of text.split("\n")) {
                    const [path, size, modified] = line.split("\t");
                    if (!path)
                        continue;
                    const slash = path.lastIndexOf("/");
                    list.push({ path, name: path.slice(slash + 1), dir: path.slice(0, slash), size: Number(size) || 0, modified: Number(modified) || 0 });
                }
                root.results = list;
                root.searching = false;
            }
        }
    }
}
