pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.core.format
import qs.core.nightlight
import qs.core.widgets
import qs.services

// View model da energia da central (a bateria, o perfil de energia e a
// bateria dos dispositivos Bluetooth) e, até a barra lateral sair, da seção
// Tela dela.
Singleton {
    id: root

    // Bateria
    readonly property bool hasBattery: Battery.available
    readonly property real percentage: Battery.percentage
    readonly property bool charging: Battery.charging
    readonly property bool low: Battery.isLow
    // Embaixo da porcentagem: carregada, carregando ou o tempo restante.
    readonly property string batteryNote: Battery.full ? "Carregada" : Battery.charging ? "Carregando" : Battery.timeRemaining > 0 ? Format.duration(Battery.timeRemaining) : ""

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

    // O painel aparece com algo a mostrar.
    readonly property bool any: hasBattery || profilesAvailable || devices.length > 0

    // Tela: uma entrada por tela com brilho ajustável (a integrada e os
    // monitores externos por DDC/CI).
    readonly property bool hasBrightness: Brightness.anyAvailable
    readonly property var brightnessScreens: Brightness.screens
    readonly property real brightness: Brightness.shownValue

    function setBrightness(id: string, v: real): void {
        Brightness.setScreen(id, v);
    }

    // "Não apagar a tela" (a ociosidade fica na feature idle; aqui só o botão).
    readonly property bool keepAwake: Config.idleInhibit
    readonly property bool idleEnabled: Config.idleEnabled

    function setKeepAwake(on: bool): void {
        Config.idleInhibit = on;
    }

    // Luz noturna: ligar ou desligar agora (até a próxima virada) e a temperatura.
    readonly property bool nightLightAvailable: NightLight.available
    readonly property bool nightLightOn: NightSchedule.on
    readonly property string nightLightStatus: NightSchedule.status
    readonly property int nightLightTemp: Config.nightLightTemp

    function setNightLight(on: bool): void {
        NightSchedule.setOn(on);
    }

    function setNightLightTemp(kelvin: int): void {
        Config.nightLightTemp = kelvin;
        NightSchedule.preview();
    }
}
