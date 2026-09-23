pragma Singleton

import QtQuick
import Quickshell
import qs.core.format
import qs.core.widgets
import qs.services

// View model da seção Bluetooth. A busca por dispositivos novos só roda
// quando o usuário pede (ela gasta bateria e deixa o aparelho visível).
Singleton {
    id: root

    readonly property bool available: Bluetooth.available
    readonly property bool enabled: Bluetooth.enabled
    property bool searching: false
    readonly property string status: !available ? "Sem adaptador Bluetooth" : !enabled ? "Desligado" : Bluetooth.connected.length ? `${Bluetooth.connected.length} conectado${Bluetooth.connected.length > 1 ? "s" : ""}` : "Nenhum dispositivo conectado"

    readonly property var paired: Bluetooth.devices.filter(d => d.paired).map(describe)
    readonly property var others: Bluetooth.devices.filter(d => !d.paired && d.name).map(describe)

    function describe(d: var): var {
        return {
            device: d,
            name: d.name || d.address,
            icon: Icons.forDevice(d.icon),
            connected: d.connected,
            busy: Bluetooth.isBusy(d),
            detail: d.connected ? (d.batteryAvailable ? `Conectado · bateria ${Format.percent(d.battery)}` : "Conectado") : d.paired ? "Pareado" : "Disponível"
        };
    }

    // Parar de procurar ao sair da seção.
    readonly property bool showing: SidebarState.isShowing("bluetooth")
    onShowingChanged: {
        if (!showing)
            searching = false;
    }

    Binding {
        target: Bluetooth
        property: "scanning"
        value: root.searching && root.showing
    }

    function setEnabled(on: bool): void {
        Bluetooth.setEnabled(on);
    }

    function toggleSearch(): void {
        searching = !searching;
    }

    function toggleConnection(item: var): void {
        Bluetooth.toggleConnection(item.device);
    }

    function forget(item: var): void {
        Bluetooth.forget(item.device);
    }
}
