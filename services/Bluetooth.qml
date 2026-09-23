pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth via BlueZ: o adaptador padrão e os dispositivos dele. Ações que
// mudam o sistema passam pelo DevMode.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false

    // Conectados primeiro, depois pareados, depois o resto; por nome.
    readonly property var devices: (adapter?.devices.values ?? []).slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || (a.name || a.address).localeCompare(b.name || b.address))
    readonly property var connected: devices.filter(d => d.connected)

    // Procura dispositivos enquanto alguém mostra a lista.
    property bool scanning: false

    Binding {
        target: root.adapter
        property: "discovering"
        value: root.enabled && !DevMode.active
        when: root.adapter !== null && root.scanning
    }

    function isBusy(device: var): bool {
        return device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting;
    }

    function setEnabled(on: bool): void {
        if (adapter && !DevMode.simulate(on ? "Ligar o Bluetooth" : "Desligar o Bluetooth"))
            adapter.enabled = on;
    }

    function toggleConnection(device: var): void {
        const label = `${device.connected ? "Desconectar" : "Conectar"} ${device.name || device.address}`;
        if (DevMode.simulate(label))
            return;
        if (device.connected)
            device.disconnect();
        else if (!device.paired)
            device.pair();
        else
            device.connect();
    }

    function forget(device: var): void {
        if (!DevMode.simulate(`Esquecer ${device.name || device.address}`))
            device.forget();
    }
}
