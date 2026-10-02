pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.core.format
import qs.core.nightlight
import qs.core.widgets
import qs.services

// View model das seções Bateria e Tela.
Singleton {
    id: root

    // Bateria
    readonly property bool hasBattery: Battery.available
    readonly property real percentage: Battery.percentage
    readonly property bool charging: Battery.charging
    readonly property string icon: Battery.charging ? Icons.batteryCharging : Icons.level(Icons.battery, Battery.percentage)
    readonly property string status: !hasBattery ? "Sem bateria (ligado na tomada)" : Battery.full ? "Carregada" : Battery.charging ? "Carregando" : Battery.onBattery ? "Na bateria" : "Na tomada"
    readonly property string remaining: Battery.timeRemaining > 0 ? `${Format.duration(Battery.timeRemaining)} ${Battery.charging ? "para carregar" : "restantes"}` : ""
    readonly property string health: isFinite(Battery.health) ? Format.percent(Battery.health) : ""
    readonly property string rate: Math.abs(Battery.changeRate) > 0.1 ? `${Format.number(Math.abs(Battery.changeRate), 1)} W` : ""

    // Perfil de energia
    readonly property int profile: Battery.profile
    readonly property var profiles: [
        { label: "Economia", value: 0 },
        { label: "Equilibrado", value: 1 },
        ...(Battery.hasPerformance ? [{ label: "Desempenho", value: 2 }] : [])
    ]
    readonly property string profileDescription: ["Menos consumo, menos desempenho", "O padrão do sistema", "Desempenho máximo, mais consumo"][profile] ?? ""

    function setProfile(value: int): void {
        Battery.setProfile(value);
    }

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
