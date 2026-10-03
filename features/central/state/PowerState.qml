pragma Singleton

import QtQuick
import Quickshell
import qs.core.format
import qs.core.widgets
import qs.services

// View model da energia da central: o tile "Bateria" (ou "Energia", sem
// bateria) e a página dele: a bateria, o perfil de energia e a bateria dos
// dispositivos Bluetooth conectados.
Singleton {
    id: root

    // Bateria
    readonly property bool hasBattery: Battery.available
    readonly property real percentage: Battery.percentage
    readonly property bool charging: Battery.charging
    readonly property bool low: Battery.isLow
    // Embaixo da porcentagem: carregada, carregando ou o tempo restante.
    readonly property string batteryNote: note(snapshot)

    // Perfil de energia: um botão por perfil, o de desempenho só se houver.
    readonly property bool profilesAvailable: Battery.profilesAvailable
    readonly property int profile: Battery.profile
    readonly property var profileButtons: [
        { value: 0, icon: Icons.eco },
        { value: 1, icon: Icons.balance },
        ...(Battery.hasPerformance ? [{ value: 2, icon: Icons.rocket }] : [])
    ]

    function setProfile(value: int): void {
        Battery.setProfile(value);
    }

    // Dispositivos Bluetooth conectados que informam a bateria.
    readonly property var devices: withBattery(Bluetooth.devices)

    function withBattery(list: var): var {
        return (list ?? []).filter(d => d.connected && d.batteryAvailable).map(d => ({ name: d.name || d.address, icon: Icons.forDevice(d.icon), battery: d.battery }));
    }

    // O tile aparece com algo a mostrar.
    readonly property bool any: hasBattery || profilesAvailable || devices.length > 0

    // Tile: "Bateria" com a carga e o tempo, ou "Energia" com o perfil (ou
    // quantos dispositivos). Pouca carga, sem carregar: o ícone na cor de
    // erro, como na barra.
    readonly property var snapshot: ({
            hasBattery: hasBattery,
            percentage: percentage,
            full: Battery.full,
            charging: charging,
            timeRemaining: Battery.timeRemaining,
            profilesAvailable: profilesAvailable,
            profile: profile,
            devices: devices.length
        })
    readonly property string title: hasBattery ? "Bateria" : "Energia"
    readonly property string status: statusLine(snapshot)
    readonly property string icon: hasBattery ? (charging ? Icons.batteryCharging : low ? Icons.batteryAlert : Icons.level(Icons.battery, percentage)) : profilesAvailable ? (profileButtons[profile]?.icon ?? Icons.balance) : Icons.battery[7]

    // Carregada, carregando ou o tempo restante ("" sem estimativa).
    function note(s: var): string {
        return s.full ? "Carregada" : s.charging ? "Carregando" : s.timeRemaining > 0 ? Format.duration(s.timeRemaining) : "";
    }

    // "78% · 1 h 52 min", "40% · Carregando", "78%"; sem bateria, o nome do
    // perfil ou "N dispositivos".
    function statusLine(s: var): string {
        if (s.hasBattery)
            return [Format.percent(s.percentage), note(s)].filter(x => x).join(" · ");
        if (s.profilesAvailable)
            return Battery.profileNames[s.profile] ?? "";
        return s.devices === 1 ? "1 dispositivo" : `${s.devices} dispositivos`;
    }
}
