pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.config
import qs.core.theme
import qs.services

// Papel de parede de cada monitor: de onde vem (o tema ativo ou o de outro
// tema), o modo (auto, animado ou estático) e se deve animar agora. Todos os
// sinais de pausa se juntam aqui, numa decisão por monitor; a ui só liga ou
// desliga a animação.
Singleton {
    id: root

    readonly property int fadeDuration: ThemeManager.anim.extraLarge
    readonly property var monitors: Config.wallpaperMonitors ?? {}

    function nameOf(screen: var): string {
        return screen?.name ?? "";
    }

    // Tema cujo papel o monitor usa (o ativo, se não escolheu outro).
    function sourceTheme(screen: var): string {
        const own = monitors[nameOf(screen)]?.source ?? "";
        return own && ThemeManager.themes.some(t => t.id === own) ? own : ThemeManager.current;
    }

    // { static, shader, fps } daquele monitor.
    function source(screen: var): var {
        return ThemeManager.wallpaperFor(sourceTheme(screen));
    }

    function mode(screen: var): string {
        return monitors[nameOf(screen)]?.mode ?? Config.wallpaperMode;
    }

    function setMonitor(name: string, fields: var): void {
        const all = Object.assign({}, monitors);
        const entry = Object.assign({}, all[name] ?? {}, fields);
        for (const k of Object.keys(entry)) {
            if (entry[k] === "" || entry[k] === null)
                delete entry[k];
        }
        if (Object.keys(entry).length)
            all[name] = entry;
        else
            delete all[name];
        Config.wallpaperMonitors = all;
    }

    // Se o efeito aparece (em vez da imagem parada): depende do modo, de o papel
    // ter efeito e, no auto, de estar na tomada.
    function showsEffect(screen: var): bool {
        const m = mode(screen);
        if (m === "static" || !source(screen).shader)
            return false;
        if (m === "auto" && Config.wallpaperBatteryStatic && Battery.available && Battery.onBattery)
            return false;
        return true;
    }

    // Se o efeito deve rodar agora. Pausado, o último quadro fica na tela e o
    // custo cai a zero (nada redesenha). Tela bloqueada, app em tela cheia ou
    // tela apagada pausam; no modo estrito, qualquer janela no workspace também.
    function shouldAnimate(screen: var): bool {
        if (!showsEffect(screen) || Session.locked)
            return false;
        if (Hypr.hasFullscreen(screen) || Hypr.isDpmsOff(screen))
            return false;
        if (Config.wallpaperStrict && !Hypr.isScreenEmpty(screen))
            return false;
        return true;
    }

    readonly property int fps: Math.max(5, Math.min(60, Config.wallpaperFps))
    readonly property bool fullRes: Config.wallpaperFullRes
    readonly property int fill: Config.wallpaperFill === "fit" ? Image.PreserveAspectFit : Image.PreserveAspectCrop

    IpcHandler {
        target: "wallpaper"

        // Modo geral: auto, animated, static ou toggle (entre animado e estático).
        function mode(mode: string): void {
            if (mode === "toggle")
                Config.wallpaperMode = Config.wallpaperMode === "static" ? "animated" : "static";
            else if (["auto", "animated", "static"].includes(mode))
                Config.wallpaperMode = mode;
        }

        // Modo de um monitor (auto, animated, static; default volta ao geral).
        function modeFor(monitor: string, mode: string): void {
            root.setMonitor(monitor, { mode: ["auto", "animated", "static"].includes(mode) ? mode : "" });
        }

        function get(): string {
            return Config.wallpaperMode;
        }
    }
}
