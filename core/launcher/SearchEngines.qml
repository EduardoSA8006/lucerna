pragma Singleton

import QtQuick
import Quickshell

// Buscadores da categoria Web do launcher. Só dados: o launcher usa, e as
// configurações escolhem o preferido (Config.launcherSearchEngine).
Singleton {
    readonly property var all: [
        { id: "duckduckgo", name: "DuckDuckGo", url: "https://duckduckgo.com/?q=%s" },
        { id: "google", name: "Google", url: "https://www.google.com/search?q=%s" },
        { id: "wikipedia", name: "Wikipédia", url: "https://pt.wikipedia.org/w/index.php?search=%s" },
        { id: "youtube", name: "YouTube", url: "https://www.youtube.com/results?search_query=%s" },
        { id: "github", name: "GitHub", url: "https://github.com/search?q=%s" }
    ]
}
