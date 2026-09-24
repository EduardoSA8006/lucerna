pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.core.nightlight
import qs.services

// View model de Configurações → Luz noturna. O horário fica no NightSchedule;
// a feature nightlight aplica.
Singleton {
    id: root

    readonly property bool available: NightLight.available
    readonly property var schedules: [
        { label: "Pôr do sol", value: "sun" },
        { label: "Horário fixo", value: "custom" },
        { label: "Sempre", value: "always" }
    ]
    // De 15 em 15 minutos.
    readonly property var clockOptions: Array.from({ length: 96 }, (_, i) => {
        const text = NightSchedule.clock(i * 15);
        return { label: text, value: text };
    })

    // Um horário fora da lista (editado à mão) entra nela para aparecer escolhido.
    function clockOptionsFor(value: string): var {
        if (clockOptions.some(o => o.value === value))
            return clockOptions;
        return clockOptions.concat([{ label: value, value: value }]).sort((a, b) => a.value.localeCompare(b.value));
    }

    readonly property string sunText: {
        const sun = NightSchedule.sunToday;
        if (!sun)
            return "";
        if (sun.polar)
            return sun.polar === "day" ? "Hoje o sol não se põe" : "Hoje o sol não nasce";
        return `Hoje: pôr do sol às ${NightSchedule.clock(sun.sunset)}, nascer às ${NightSchedule.clock(sun.sunrise)}`;
    }

    function setTemp(kelvin: int): void {
        Config.nightLightTemp = kelvin;
        NightSchedule.preview();
    }
}
