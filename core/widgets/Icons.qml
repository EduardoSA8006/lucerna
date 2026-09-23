pragma Singleton

import Quickshell

// Glifos Material Design da Nerd Font usados pelo shell.
Singleton {
    readonly property string apps: "\u{f003b}"
    readonly property string magnify: "\u{f0349}"
    readonly property string terminal: "\u{f018d}"
    readonly property string application: "\u{f08c6}"
    readonly property string close: "\u{f0156}"
    readonly property string check: "\u{f012c}"
    readonly property string arrowRight: "\u{f0054}"

    readonly property string volumeHigh: "\u{f057e}"
    readonly property string volumeMedium: "\u{f0580}"
    readonly property string volumeLow: "\u{f057f}"
    readonly property string volumeOff: "\u{f0581}"

    readonly property string brightnessLow: "\u{f00de}"
    readonly property string brightnessMedium: "\u{f00df}"
    readonly property string brightnessHigh: "\u{f00e0}"

    readonly property var wifi: ["\u{f092f}", "\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"]
    readonly property string wifiOff: "\u{f05aa}"
    readonly property string ethernet: "\u{f0200}"
    readonly property string offline: "\u{f0319}"

    readonly property var battery: ["\u{f008e}", "\u{f007a}", "\u{f007b}", "\u{f007c}", "\u{f007d}", "\u{f007e}", "\u{f007f}", "\u{f0080}", "\u{f0081}", "\u{f0082}", "\u{f0079}"]
    readonly property string batteryCharging: "\u{f0084}"
    readonly property string batteryAlert: "\u{f0083}"

    readonly property string bell: "\u{f009a}"
    readonly property string bellOutline: "\u{f009c}"
    readonly property string bellBadge: "\u{f116b}"
    readonly property string bellSleep: "\u{f00a0}"
    readonly property string clearAll: "\u{f039f}"

    readonly property string palette: "\u{f03d8}"
    readonly property string power: "\u{f0425}"
    readonly property string lock: "\u{f033e}"
    readonly property string lockOpen: "\u{f0fc6}"
    readonly property string sleep: "\u{f04b2}"
    readonly property string restart: "\u{f0709}"
    readonly property string logout: "\u{f0343}"

    // Escolhe o glifo de uma escala (lista) conforme uma fração de 0 a 1.
    function level(list: var, fraction: real): string {
        const i = Math.round(Math.max(0, Math.min(1, fraction)) * (list.length - 1));
        return list[i];
    }
}
