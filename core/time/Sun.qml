pragma Singleton

import QtQuick
import Quickshell

// Nascer e pôr do sol calculados na hora, sem rede (as equações da NOAA, com
// erro de um minuto ou dois). Os horários saem no fuso do sistema.
Singleton {
    // { sunrise, sunset } em minutos desde a meia-noite local do dia `date`,
    // ou { polar: "day" | "night" } quando o sol não nasce ou não se põe.
    function times(date: var, latitude: real, longitude: real): var {
        const rad = Math.PI / 180;
        const dayOfYear = Math.round((new Date(date.getFullYear(), date.getMonth(), date.getDate()) - new Date(date.getFullYear(), 0, 0)) / 86400000);
        const g = 2 * Math.PI / 365 * (dayOfYear - 1);
        const eqTime = 229.18 * (0.000075 + 0.001868 * Math.cos(g) - 0.032077 * Math.sin(g) - 0.014615 * Math.cos(2 * g) - 0.040849 * Math.sin(2 * g));
        const decl = 0.006918 - 0.399912 * Math.cos(g) + 0.070257 * Math.sin(g) - 0.006758 * Math.cos(2 * g) + 0.000907 * Math.sin(2 * g) - 0.002697 * Math.cos(3 * g) + 0.00148 * Math.sin(3 * g);
        const cosH = Math.cos(90.833 * rad) / (Math.cos(latitude * rad) * Math.cos(decl)) - Math.tan(latitude * rad) * Math.tan(decl);
        if (cosH > 1)
            return { polar: "night" };
        if (cosH < -1)
            return { polar: "day" };
        const hourAngle = Math.acos(cosH) / rad;
        const offset = date.getTimezoneOffset();
        const wrap = m => ((m % 1440) + 1440) % 1440;
        return {
            sunrise: wrap(720 - 4 * (longitude + hourAngle) - eqTime - offset),
            sunset: wrap(720 - 4 * (longitude - hourAngle) - eqTime - offset)
        };
    }
}
