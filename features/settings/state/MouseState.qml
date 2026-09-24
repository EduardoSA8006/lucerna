pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.services

// View model de Configurações → Mouse. Cada opção mostra o valor em uso: o
// que foi mudado aqui ou, senão, o do hyprland.lua. Mudar grava só aquela
// opção na config (a feature input aplica); restaurar tira tudo e recarrega o
// hyprland.lua.
Singleton {
    id: root

    readonly property var names: [
        "input.sensitivity", "input.accel_profile", "input.left_handed", "input.natural_scroll",
        "input.scroll_factor", "input.follow_mouse",
        "input.touchpad.tap_to_click", "input.touchpad.natural_scroll", "input.touchpad.disable_while_typing",
        "input.touchpad.clickfinger_behavior", "input.touchpad.scroll_factor", "input.touchpad.middle_button_emulation",
        "input.touchpad.drag_lock", "input.touchpad.tap_and_drag"
    ]

    function value(name: string, fallback: var): var {
        const own = Config.inputOptions ?? {};
        if (name in own)
            return own[name];
        return Input.option(name) ?? fallback;
    }

    function set(name: string, v: var): void {
        const own = Object.assign({}, Config.inputOptions ?? {});
        own[name] = v;
        Config.inputOptions = own;
    }

    // Ponteiro
    readonly property real sensitivity: Number(value("input.sensitivity", 0))
    readonly property string accel: String(value("input.accel_profile", "") || "adaptive")
    readonly property bool leftHanded: !!value("input.left_handed", false)
    readonly property bool naturalScroll: !!value("input.natural_scroll", false)
    readonly property real scrollFactor: Number(value("input.scroll_factor", 1))
    // 1: o foco vai para a janela sob o mouse; 0: só ao clicar.
    readonly property int followMouse: Number(value("input.follow_mouse", 1)) === 0 ? 0 : 1

    // Touchpad
    readonly property bool hasTouchpad: Input.touchpads.length > 0
    readonly property bool tapToClick: !!value("input.touchpad.tap_to_click", true)
    readonly property bool touchpadNatural: !!value("input.touchpad.natural_scroll", false)
    readonly property bool disableWhileTyping: !!value("input.touchpad.disable_while_typing", true)
    readonly property bool clickfinger: !!value("input.touchpad.clickfinger_behavior", false)
    readonly property real touchpadScroll: Number(value("input.touchpad.scroll_factor", 1))
    readonly property bool middleEmulation: !!value("input.touchpad.middle_button_emulation", false)
    readonly property bool tapAndDrag: !!value("input.touchpad.tap_and_drag", true)
    readonly property bool dragLock: !!value("input.touchpad.drag_lock", false)

    // Dispositivos: cada mouse pode ter a própria velocidade.
    readonly property var mice: Input.mice
    readonly property var devices: Config.mouseDevices ?? {}

    function hasOwnSpeed(name: string): bool {
        return name in devices;
    }

    function deviceSpeed(name: string): real {
        return devices[name]?.sensitivity ?? sensitivity;
    }

    function setDeviceSpeed(name: string, v: real): void {
        const all = Object.assign({}, devices);
        all[name] = Object.assign({}, all[name] ?? {}, { sensitivity: Math.round(v * 100) / 100 });
        Config.mouseDevices = all;
    }

    // Desligar a velocidade própria: o valor volta ao geral na hora.
    function clearDevice(name: string): void {
        const all = Object.assign({}, devices);
        delete all[name];
        Config.mouseDevices = all;
        Input.setDevice(name, { sensitivity: sensitivity });
    }

    readonly property bool customized: Object.keys(Config.inputOptions ?? {}).some(k => names.includes(k)) || Object.keys(devices).length > 0

    function reset(): void {
        const own = Object.assign({}, Config.inputOptions ?? {});
        for (const n of names)
            delete own[n];
        Config.inputOptions = own;
        Config.mouseDevices = {};
        Input.reload();
    }
}
