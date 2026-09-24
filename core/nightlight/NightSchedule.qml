pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.core.time

// Horário da luz noturna, compartilhado pela feature que aplica, pela central
// lateral e pelas configurações. O horário vem do pôr e do nascer do sol (pela
// cidade do clima, calculado sem rede), de um de/até fixo ou é "sempre". Entra e sai aos poucos, em 30 min. Ligar ou desligar à mão
// vale até a próxima virada do horário; depois o horário volta a mandar.
Singleton {
    id: root

    readonly property int dayTemp: 6500
    readonly property int rampMinutes: 30

    property real now: Date.now()

    readonly property bool enabled: Config.nightLightEnabled
    readonly property string schedule: Config.nightLightSchedule
    readonly property var location: Config.weatherLocation
    // Pôr do sol sem cidade escolhida: usa o de/até.
    readonly property bool needsLocation: schedule === "sun" && !location

    function toMinutes(hhmm: string): int {
        const [h, m] = String(hhmm).split(":").map(Number);
        return ((h || 0) * 60 + (m || 0)) % 1440;
    }

    function clock(minutes: real): string {
        const m = Math.round(minutes) % 1440;
        return `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;
    }

    // Nascer e pôr do sol de hoje na cidade do clima (ou null).
    readonly property var sunToday: location ? Sun.times(new Date(now), location.latitude, location.longitude) : null

    // A noite de hoje: { start, end } em minutos, ou { always } / { never }.
    readonly property var night: {
        if (schedule === "always")
            return { always: true };
        if (schedule === "sun" && location) {
            const sun = sunToday;
            if (sun.polar === "day")
                return { never: true };
            if (sun.polar === "night")
                return { always: true };
            return { start: sun.sunset, end: sun.sunrise };
        }
        return { start: toMinutes(Config.nightLightFrom), end: toMinutes(Config.nightLightTo) };
    }

    readonly property real minuteOfDay: {
        const d = new Date(now);
        return d.getHours() * 60 + d.getMinutes() + d.getSeconds() / 60;
    }

    // 0 (dia) a 1 (noite cheia), com a rampa nas duas pontas.
    readonly property real scheduledFactor: {
        if (night.always)
            return 1;
        if (night.never)
            return 0;
        const length = (night.end - night.start + 1440) % 1440;
        const elapsed = (minuteOfDay - night.start + 1440) % 1440;
        if (length === 0 || elapsed >= length)
            return 0;
        const ramp = Math.min(rampMinutes, length / 2);
        return Math.min(1, elapsed / ramp, (length - elapsed) / ramp);
    }
    readonly property bool scheduledOn: scheduledFactor > 0

    readonly property var override: {
        const o = Config.nightLightOverride;
        return o && now < o.until ? o : null;
    }

    readonly property real factor: !enabled ? 0 : override ? (override.on ? 1 : 0) : scheduledFactor
    readonly property bool on: factor > 0

    // Prévia da temperatura enquanto ajusta (de dia não daria para ver).
    property bool previewing: false

    readonly property int temperature: previewing ? Config.nightLightTemp : on ? Math.round(dayTemp - (dayTemp - Config.nightLightTemp) * factor) : 0

    // Quando o horário vira de novo (em ms), para o "até" da mão.
    function nextChange(): real {
        if (night.always || night.never)
            return 0;
        const target = scheduledOn ? night.end : night.start;
        const minutes = (target - minuteOfDay + 1440) % 1440 || 1440;
        return now + minutes * 60000;
    }

    readonly property string status: {
        if (!enabled)
            return "Desligada";
        if (override) {
            const until = new Date(override.until);
            return `${override.on ? "Ligada" : "Desligada"} até ${clock(until.getHours() * 60 + until.getMinutes())}`;
        }
        if (night.always)
            return "Ligada";
        if (night.never)
            return "O sol não se põe hoje";
        return scheduledOn ? `Ligada até ${clock(night.end)}` : `Liga às ${clock(night.start)}`;
    }

    function setOn(value: bool): void {
        if (!enabled) {
            if (!value)
                return;
            Config.nightLightEnabled = true;
            Config.nightLightOverride = null;
        } else if (!value && (night.always || night.never)) {
            Config.nightLightEnabled = false;
            return;
        }
        Config.nightLightOverride = value === scheduledOn || night.always || night.never ? null : { on: value, until: nextChange() };
    }

    function preview(): void {
        previewing = true;
        previewEnd.restart();
    }

    Timer {
        id: previewEnd

        interval: 3000
        onTriggered: root.previewing = false
    }

    // A cada 30 s (a rampa anda de minuto em minuto; o Hyprland suaviza).
    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 30000
        onTriggered: {
            root.now = Date.now();
            if (Config.nightLightOverride && !root.override)
                Config.nightLightOverride = null;
        }
    }
}
