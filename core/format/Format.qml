pragma Singleton

import QtQuick
import Quickshell

// Formatação de números, tamanhos e tempos no padrão brasileiro.
Singleton {
    readonly property var locale: Qt.locale("pt_BR")

    function number(value: real, decimals: int): string {
        return Number(value).toLocaleString(locale, "f", decimals);
    }

    function percent(fraction: real): string {
        return `${Math.round(fraction * 100)}%`;
    }

    // 1536 → "1,5 KiB"
    function bytes(value: real): string {
        const units = ["B", "KiB", "MiB", "GiB", "TiB"];
        let i = 0;
        while (value >= 1024 && i < units.length - 1) {
            value /= 1024;
            i++;
        }
        return `${number(value, i === 0 || value >= 100 ? 0 : 1)} ${units[i]}`;
    }

    function rate(bytesPerSecond: real): string {
        return `${bytes(bytesPerSecond)}/s`;
    }

    // 3725 s → "1 h 2 min"
    function duration(seconds: real): string {
        const d = Math.floor(seconds / 86400);
        const h = Math.floor(seconds % 86400 / 3600);
        const m = Math.floor(seconds % 3600 / 60);
        if (d > 0)
            return `${d} d ${h} h`;
        if (h > 0)
            return `${h} h ${m} min`;
        return `${m} min`;
    }

    // 83 s → "1:23"
    function clock(seconds: real): string {
        if (!isFinite(seconds) || seconds < 0)
            seconds = 0;
        const m = Math.floor(seconds / 60);
        const s = Math.floor(seconds % 60);
        return `${m}:${s < 10 ? "0" : ""}${s}`;
    }

    function capitalize(text: string): string {
        return text ? text.charAt(0).toUpperCase() + text.slice(1) : "";
    }
}
