pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.services

// Reaplica o arranjo de monitores salvo para o conjunto conectado: ao iniciar
// e quando um monitor entra ou sai. Sem interface própria; o arranjo se monta
// em Configurações → Monitores.
Singleton {
    id: root

    readonly property string setup: Monitors.setup

    onSetupChanged: restore()

    function restore(): void {
        const saved = (Config.monitorSetups ?? {})[setup];
        if (!setup || !saved)
            return;
        // O arranjo é salvo pela chave do monitor; a porta pode ter mudado.
        const specs = Monitors.monitors.filter(m => saved[m.key]).map(m => Object.assign({}, saved[m.key], { name: m.name }));
        if (specs.length === Monitors.monitors.length)
            Monitors.apply(specs);
    }
}
