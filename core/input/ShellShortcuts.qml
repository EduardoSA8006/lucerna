pragma Singleton

import QtQuick
import Quickshell

// Os atalhos do próprio shell: os padrões e o que o usuário mudou
// (Config.shellShortcuts: { acao: [{ mods, trigger }] }; lista vazia = sem
// atalho). Só dados: a feature input aplica e as configurações editam.
// No ambiente de desenvolvimento o Mod é Alt (o Hyprland de fora fica com o Super).
Singleton {
    id: root

    readonly property string mod: Quickshell.env("LUCERNA_DEV") === "1" ? "ALT" : "SUPER"

    readonly property var defaults: [
        { id: "launcher", keys: [{ mods: mod, trigger: "space" }] },
        { id: "dashboard", keys: [{ mods: mod, trigger: "d" }] },
        { id: "settings", keys: [{ mods: mod, trigger: "s" }] },
        { id: "notifications", keys: [{ mods: mod, trigger: "n" }] },
        { id: "sidebar", keys: [{ mods: mod, trigger: "c" }] },
        { id: "clipboard", keys: [{ mods: mod, trigger: "v" }] },
        { id: "themes", keys: [{ mods: mod, trigger: "t" }] },
        { id: "capture", keys: [{ mods: "", trigger: "Print" }] },
        { id: "capture-screen", keys: [{ mods: "SHIFT", trigger: "Print" }] },
        { id: "capture-window", keys: [{ mods: "CTRL", trigger: "Print" }] },
        { id: "record", keys: [{ mods: mod, trigger: "Print" }] },
        { id: "power", keys: [{ mods: mod, trigger: "Escape" }] },
        { id: "lock", keys: [{ mods: mod, trigger: "l" }] },
        { id: "dnd", keys: [] },
        { id: "volume-up", keys: [{ mods: "", trigger: "XF86AudioRaiseVolume" }] },
        { id: "volume-down", keys: [{ mods: "", trigger: "XF86AudioLowerVolume" }] },
        { id: "mute", keys: [{ mods: "", trigger: "XF86AudioMute" }] },
        { id: "mic-mute", keys: [{ mods: "", trigger: "XF86AudioMicMute" }] },
        { id: "play-pause", keys: [{ mods: "", trigger: "XF86AudioPlay" }] },
        { id: "next", keys: [{ mods: "", trigger: "XF86AudioNext" }] },
        { id: "previous", keys: [{ mods: "", trigger: "XF86AudioPrev" }] },
        { id: "brightness-up", keys: [{ mods: "", trigger: "XF86MonBrightnessUp" }] },
        { id: "brightness-down", keys: [{ mods: "", trigger: "XF86MonBrightnessDown" }] }
    ]

    // [{ id, keys, custom }] com as mudanças do usuário por cima dos padrões.
    function effective(overrides: var): var {
        const own = overrides ?? {};
        return defaults.map(d => ({ id: d.id, keys: own[d.id] ?? d.keys, custom: own[d.id] !== undefined }));
    }

    function defaultKeys(id: string): var {
        return defaults.find(d => d.id === id)?.keys ?? [];
    }

    // Modificadores em ordem fixa, para comparar e para montar a tecla do bind.
    function normalizeMods(mods: string): string {
        const set = String(mods ?? "").toUpperCase().split(/[\s+]+/).filter(m => m);
        return ["SUPER", "CTRL", "ALT", "SHIFT"].filter(m => set.includes(m)).join(" ");
    }

    function same(a: var, b: var): bool {
        return normalizeMods(a.mods) === normalizeMods(b.mods) && String(a.trigger).toLowerCase() === String(b.trigger).toLowerCase();
    }

    // "SUPER + SHIFT + q" → { mods: "SUPER SHIFT", trigger: "q" }.
    function fromKey(key: string): var {
        const parts = String(key).split(" + ");
        return { mods: parts.slice(0, -1).join(" "), trigger: parts[parts.length - 1] };
    }

    // Bits do Hyprland (modmask em `hyprctl binds -j`).
    function modsFromMask(mask: int): string {
        const out = [];
        if (mask & 64)
            out.push("SUPER");
        if (mask & 4)
            out.push("CTRL");
        if (mask & 8)
            out.push("ALT");
        if (mask & 1)
            out.push("SHIFT");
        return out.join(" ");
    }
}
