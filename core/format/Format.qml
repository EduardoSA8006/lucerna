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

    readonly property var units: ["B", "KiB", "MiB", "GiB", "TiB"]

    // O índice em `units` para `value` bytes: a maior unidade em que o número
    // fica abaixo de 1000 já arredondado (1010 MiB → GiB, não "1.010 MiB").
    function unitIndex(value: real): int {
        let i = 0;
        while (value >= 999.5 && i < units.length - 1) {
            value /= 1024;
            i++;
        }
        return i;
    }

    // Casas decimais de um número já na unidade `i`: nenhuma em bytes e a
    // partir de 100 (99,96 sai "100", não "100,0"); senão, uma.
    function decimals(value: real, i: int): int {
        return i === 0 || value >= 99.95 ? 0 : 1;
    }

    // 1536 → "1,5 KiB"
    function bytes(value: real): string {
        const i = unitIndex(value);
        const v = value / Math.pow(1024, i);
        return `${number(v, decimals(v, i))} ${units[i]}`;
    }

    // Usado e total na unidade do total, cada um com as suas casas:
    // "9,7 / 31,1 GiB", "4,8 / 224 GiB", "454 / 915 GiB".
    function usage(used: real, total: real): string {
        const i = unitIndex(total);
        const u = used / Math.pow(1024, i);
        const t = total / Math.pow(1024, i);
        return `${number(u, decimals(u, i))} / ${number(t, decimals(t, i))} ${units[i]}`;
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

    // Quanto tempo desde `at` (Date), visto em `now`: "agora", "há 5 min",
    // "14:03" (hoje) ou "12/09".
    function since(at: var, now: var): string {
        const minutes = Math.floor((now - at) / 60000);
        if (minutes < 1)
            return "agora";
        if (minutes < 60)
            return `há ${minutes} min`;
        if (at.toDateString() === now.toDateString())
            return Qt.formatTime(at, "HH:mm");
        return Qt.formatDate(at, "dd/MM");
    }

    function capitalize(text: string): string {
        return text ? text.charAt(0).toUpperCase() + text.slice(1) : "";
    }
}
