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
    // Tile das ações: o dispositivo conectado (ou quantos), ou o estado; o
    // ícone e se há algum conectado.
    readonly property bool connected: Bluetooth.connected.length > 0
    readonly property string summary: !available ? "Sem adaptador" : !enabled ? "Desligado" : Bluetooth.connected.length === 1 ? (Bluetooth.connected[0].name || Bluetooth.connected[0].address) : connected ? `${Bluetooth.connected.length} conectados` : "Ligado"
    readonly property string icon: !available || !enabled ? Icons.bluetoothOff : connected ? Icons.bluetoothConnected : Icons.bluetooth

    readonly property var paired: Bluetooth.devices.filter(d => d.paired).map(describe)
    readonly property var others: Bluetooth.devices.filter(d => !d.paired && d.name).map(describe)

    function describe(d: var): var {
        return {
            device: d,
            name: d.name || d.address,
            icon: Icons.forDevice(d.icon),
            connected: d.connected,
            busy: Bluetooth.isBusy(d),
            detail: d.connected ? (d.batteryAvailable ? "Conectado · bateria " + Format.percent(d.battery) : "Conectado") : d.paired ? "Pareado" : "Disponível"
        };
    }

    // Parar de procurar ao sair da página.
    readonly property bool showing: CentralState.open && CentralState.page === "bluetooth"
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
