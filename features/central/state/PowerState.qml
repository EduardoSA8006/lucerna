pragma Singleton

import QtQuick
import Quickshell
import qs.core.format
import qs.core.widgets
import qs.services

// View model da energia da central: o tile "Bateria" (ou "Energia", sem
// bateria) e a página dele: o card da bateria, o perfil de energia, o gráfico
// do consumo e a bateria dos dispositivos Bluetooth conectados.
Singleton {
    id: root

    // Bateria
    readonly property bool hasBattery: Battery.available
    readonly property real percentage: Battery.percentage
    readonly property bool charging: Battery.charging
    readonly property bool low: Battery.isLow
    // Embaixo da porcentagem: carregada, carregando ou o tempo restante.
    readonly property string batteryNote: note(snapshot)
    // A cor do card: "accent", "warning", "danger" ou "success".
    readonly property string cardBand: band(percentage, charging, low)

    // Carregando, verde; bateria baixa (o limite das configurações), erro;
    // acima de 50%, o destaque; senão, aviso. Arredonda como a porcentagem.
    function band(percentage: real, charging: bool, low: bool): string {
        return charging ? "success" : low ? "danger" : Math.round(percentage * 100) > 50 ? "accent" : "warning";
    }

    // Gráfico do consumo da última hora: os pontos (x e y de 0 a 1) e o valor
    // de agora.
    readonly property var chart: chartPoints(Battery.history, Battery.historyAt, Battery.historySpan)
    readonly property string consumptionText: consumption(Battery.rate, charging)

    // O histórico ({ time, value }, do mais antigo ao mais novo) na janela de
    // `span` segundos até `now`: x pelo tempo, y pelo maior valor. O último
    // ponto antes da janela entra na borda esquerda e o último dela se estende
    // até agora (o UPower só grava quando o valor muda). Menos de dois pontos,
    // nenhum.
    function chartPoints(list: var, now: real, span: real): var {
        const start = now - span;
        const before = list.filter(p => p.time < start);
        const points = [...before.slice(-1).map(p => ({ time: start, value: p.value })), ...list.filter(p => p.time >= start && p.time <= now)];
        const last = points[points.length - 1];
        if (last && last.time < now)
            points.push({ time: now, value: last.value });
        if (points.length < 2)
            return [];
        const top = Math.max(...points.map(p => p.value));
        return points.map(p => ({ x: (p.time - start) / span, y: top > 0 ? p.value / top : 0 }));
    }

    // "8,1 W"; carregando, "Carregando · 25,3 W"; sem a medida, só o estado.
    function consumption(rate: real, charging: bool): string {
        const watts = rate > 0 ? `${Format.number(rate, 1)} W` : "";
        return [charging ? "Carregando" : "", watts].filter(x => x).join(" · ");
    }

    // Perfil de energia: um botão de texto por perfil, o Turbo só se houver.
    // O ícone fica para o tile "Energia" de um desktop.
    readonly property bool profilesAvailable: Battery.profilesAvailable
    readonly property int profile: Battery.profile
    readonly property var profileButtons: [
        { value: 0, label: Battery.profileNames[0], icon: Icons.eco },
        { value: 1, label: Battery.profileNames[1], icon: Icons.balance },
        ...(Battery.hasPerformance ? [{ value: 2, label: Battery.profileNames[2], icon: Icons.rocket }] : [])
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
