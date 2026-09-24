pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.core.input
import qs.services

// View model de Configurações → Teclado: layouts, opções do xkb, repetição e
// teclas remapeadas. Como no mouse, só o que foi mudado aqui vai para a config;
// o resto segue o hyprland.lua.
Singleton {
    id: root

    // Layouts
    readonly property var fileLayouts: {
        const layouts = String(Input.option("input.kb_layout") ?? "us").split(",");
        const variants = String(Input.option("input.kb_variant") ?? "").split(",");
        return layouts.map((l, i) => ({ layout: l.trim(), variant: (variants[i] ?? "").trim() })).filter(l => l.layout);
    }
    readonly property var layouts: Config.keyboardLayouts ?? fileLayouts

    function layoutName(layout: string): string {
        return Input.layoutCatalog.find(l => l.name === layout)?.description ?? layout;
    }

    function variantName(layout: string, variant: string): string {
        if (!variant)
            return "Padrão";
        return (Input.variantCatalog[layout] ?? []).find(v => v.name === variant)?.description ?? variant;
    }

    readonly property var layoutOptions: Input.layoutCatalog.filter(l => !layouts.some(x => x.layout === l.name)).map(l => ({ label: l.description, detail: l.name, value: l.name }))

    function variantOptions(layout: string): var {
        return [{ label: "Padrão", value: "" }].concat((Input.variantCatalog[layout] ?? []).map(v => ({ label: v.description, detail: v.name, value: v.name })));
    }

    function setLayouts(list: var): void {
        Config.keyboardLayouts = list;
    }

    function addLayout(layout: string): void {
        if (layouts.length < 4 && !layouts.some(l => l.layout === layout))
            setLayouts(layouts.concat([{ layout, variant: "" }]));
    }

    function removeLayout(index: int): void {
        if (layouts.length > 1)
            setLayouts(layouts.filter((l, i) => i !== index));
    }

    function moveLayout(index: int, step: int): void {
        const to = index + step;
        if (to < 0 || to >= layouts.length)
            return;
        const list = layouts.slice();
        [list[index], list[to]] = [list[to], list[index]];
        setLayouts(list);
    }

    function setVariant(index: int, variant: string): void {
        setLayouts(layouts.map((l, i) => i === index ? { layout: l.layout, variant } : l));
    }

    // Opções do xkb
    readonly property var fileOptions: String(Input.option("input.kb_options") ?? "").split(",").map(o => o.trim()).filter(o => o)
    readonly property var options: Config.keyboardOptions ?? fileOptions

    function hasOption(name: string): bool {
        return options.includes(name);
    }

    function setOptions(list: var): void {
        Config.keyboardOptions = list;
    }

    // Troca a opção de um grupo (ex.: tudo o que mexe no Caps Lock) por outra.
    function setChoice(group: var, value: string): void {
        const rest = options.filter(o => !group.some(g => g.endsWith(":") ? o.startsWith(g) : o === g));
        setOptions(value ? rest.concat([value]) : rest);
    }

    function choiceOf(group: var): string {
        return options.find(o => group.some(g => g.endsWith(":") ? o.startsWith(g) : o === g)) ?? "";
    }

    function toggleOption(name: string, on: bool): void {
        const rest = options.filter(o => o !== name);
        setOptions(on ? rest.concat([name]) : rest);
    }

    // Escolhas prontas (grupo: prefixos/opções que cada uma substitui).
    readonly property var switchGroup: ["grp:"]
    readonly property var switchChoices: [
        { label: "Nenhum", value: "" },
        { label: "Alt + Shift", value: "grp:alt_shift_toggle" },
        { label: "Super + Espaço", value: "grp:win_space_toggle" },
        { label: "Ctrl + Shift", value: "grp:ctrl_shift_toggle" },
        { label: "Caps Lock", value: "grp:caps_toggle" }
    ]
    readonly property var capsGroup: ["caps:", "ctrl:swapcaps", "ctrl:nocaps"]
    readonly property var capsChoices: [
        { label: "Caps Lock (padrão)", value: "" },
        { label: "Esc", value: "caps:escape" },
        { label: "Ctrl", value: "ctrl:nocaps" },
        { label: "Backspace", value: "caps:backspace" },
        { label: "Super", value: "caps:super" },
        { label: "Trocar com Esc", value: "caps:swapescape" },
        { label: "Trocar com Ctrl esquerdo", value: "ctrl:swapcaps" },
        { label: "Desligado", value: "caps:none" }
    ]
    readonly property var composeGroup: ["compose:"]
    readonly property var composeChoices: [
        { label: "Nenhuma", value: "" },
        { label: "Alt direito", value: "compose:ralt" },
        { label: "Ctrl direito", value: "compose:rctrl" },
        { label: "Menu", value: "compose:menu" },
        { label: "Print Screen", value: "compose:prsc" },
        { label: "Caps Lock", value: "compose:caps" }
    ]
    readonly property var curated: ["grp:", "caps:", "ctrl:swapcaps", "ctrl:nocaps", "compose:", "altwin:swap_alt_win", "shift:both_capslock"]

    // As demais opções ativas (fora das escolhas prontas), com a descrição.
    readonly property var otherOptions: options.filter(o => !curated.some(c => c.endsWith(":") ? o.startsWith(c) : o === c)).map(o => ({ name: o, description: Input.optionCatalog.find(x => x.name === o)?.description ?? o }))
    readonly property var optionChoices: Input.optionCatalog.filter(o => !options.includes(o.name)).map(o => ({ label: o.description, detail: o.name, value: o.name }))

    // Digitação
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

    readonly property int repeatRate: Number(value("input.repeat_rate", 25))
    readonly property int repeatDelay: Number(value("input.repeat_delay", 600))
    readonly property bool numlock: !!value("input.numlock_by_default", false)

    // Teclas remapeadas: [{ from: "CAPS", to: { kind, value } }]
    readonly property var remaps: (Config.keyRemaps ?? []).filter(r => r?.from && r?.to?.kind)

    function keyLabel(name: string): string {
        return InputActions.prettySymbol(Input.keySymbols[name] ?? name);
    }

    function targetLabel(to: var): string {
        if (to.kind === "none")
            return "Nada (desativada)";
        const ready = InputActions.remapTargets.find(t => t.to.kind === to.kind && t.to.value === to.value);
        if (ready)
            return ready.label;
        return to.kind === "key" ? keyLabel(to.value) : InputActions.prettySymbol(to.value);
    }

    readonly property var targetOptions: InputActions.remapTargets.map((t, i) => ({ label: t.label, value: i }))

    // Editor de remapeamento: capturar a tecla de origem e escolher o destino
    // (uma pronta ou outra tecla, também capturada).
    property var remapDraft: null
    property string remapCapturing: ""

    function startRemap(): void {
        remapDraft = { from: "", to: InputActions.remapTargets[0].to };
        captureRemap("from");
    }

    function captureRemap(what: string): void {
        remapCapturing = what;
        Input.suspendBinds();
    }

    function stopRemapCapture(): void {
        remapCapturing = "";
        Input.resumeBinds();
    }

    function capturedRemapKey(code: int): bool {
        const name = Input.keyNames[String(code)];
        if (!name)
            return false;
        if (remapCapturing === "from")
            remapDraft = Object.assign({}, remapDraft, { from: name });
        else
            remapDraft = Object.assign({}, remapDraft, { to: { kind: "key", value: name } });
        stopRemapCapture();
        return true;
    }

    function setRemapTarget(index: int): void {
        remapDraft = Object.assign({}, remapDraft, { to: InputActions.remapTargets[index].to });
    }

    function cancelRemap(): void {
        stopRemapCapture();
        remapDraft = null;
    }

    function saveRemap(): void {
        if (!remapDraft?.from)
            return;
        Config.keyRemaps = remaps.filter(r => r.from !== remapDraft.from).concat([remapDraft]);
        cancelRemap();
    }

    function removeRemap(from: string): void {
        Config.keyRemaps = remaps.filter(r => r.from !== from);
    }

    readonly property var names: ["input.repeat_rate", "input.repeat_delay", "input.numlock_by_default"]
    readonly property bool customized: Config.keyboardLayouts !== null || Config.keyboardOptions !== null || remaps.length > 0 || Object.keys(Config.inputOptions ?? {}).some(k => names.includes(k))

    function reset(): void {
        const own = Object.assign({}, Config.inputOptions ?? {});
        for (const n of names)
            delete own[n];
        Config.inputOptions = own;
        Config.keyboardLayouts = null;
        Config.keyboardOptions = null;
        Config.keyRemaps = [];
        Input.reload();
    }
}
