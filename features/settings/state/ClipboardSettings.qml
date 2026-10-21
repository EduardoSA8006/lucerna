pragma Singleton

import QtQuick
import Quickshell
import qs.services

// View model de Configurações → Área de transferência. O histórico mora no
// serviço Clipboard; a feature clipboard mostra e cola.
Singleton {
    readonly property bool available: Clipboard.available
    readonly property int count: Clipboard.count
    readonly property int pinned: Clipboard.pinned
    // A mesma regra do ClipboardState (uma feature não importa outra).
    readonly property string unavailableText: {
        if (!Clipboard.client.connected)
            return "Indisponível: sem conexão com o lucernad.";
        return Clipboard.error ? `Indisponível: ${Clipboard.error}` : "Indisponível.";
    }
    readonly property var limitOptions: [25, 50, 100, 200, 500].map(n => ({ label: `${n} itens`, value: n }))

    function clear(all: bool): void {
        Clipboard.clear(all);
    }
}
