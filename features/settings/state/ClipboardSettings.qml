pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.services

// View model de Configurações → Área de transferência. O histórico mora no
// serviço Clipboard; a feature clipboard mostra e cola.
Singleton {
    readonly property bool available: Clipboard.available
    readonly property int count: Clipboard.entries.length
    readonly property int pinned: Clipboard.entries.filter(e => e.pinned).length
    readonly property var limitOptions: [25, 50, 100, 200, 500].map(n => ({ label: `${n} itens`, value: n }))

    function clear(all: bool): void {
        Clipboard.clear(all);
    }
}
