pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.core.panels
import qs.core.theme
import qs.services

// View model do seletor de temas. Também mantém as bordas do Hyprland em
// sintonia com o tema ativo, inclusive na inicialização.
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("themes")
    readonly property var screen: Hypr.focusedScreen
    readonly property var themes: ThemeManager.themes
    readonly property string current: ThemeManager.current
    readonly property int currentIndex: themes.findIndex(t => t.id === current)

    function apply(id: string): void {
        ThemeManager.apply(id);
    }

    function close(): void {
        Panels.close();
    }

    // Leva à tela de configurações, na parte de aparência.
    function openSettings(): void {
        Config.settingsTopic = "appearance";
        Panels.open("settings");
    }

    // Integração com o Hyprland
    readonly property string hyprlandConfig: Hypr.usingLua ? toLua(ThemeManager.hyprland) : ""
    readonly property string blurRule: Hypr.usingLua ? blurLua(ThemeManager.transparency.enabled && ThemeManager.blur.enabled) : ""
    readonly property string blurConfig: Hypr.usingLua ? `hl.config({ decoration = { blur = { size = ${ThemeManager.blur.size}, passes = ${ThemeManager.blur.passes} } } })` : ""

    onHyprlandConfigChanged: {
        if (hyprlandConfig)
            Hypr.evalLua(hyprlandConfig);
    }

    // Cada layer_rule é acumulada pelo Hyprland; só reenvia quando muda.
    onBlurRuleChanged: {
        if (blurRule)
            Hypr.evalLua(blurRule);
    }

    // Intensidade do desfoque: com atraso, para não mandar um comando por
    // quadro enquanto o usuário arrasta o controle.
    onBlurConfigChanged: blurDelay.restart()

    Timer {
        id: blurDelay

        interval: 120
        onTriggered: {
            if (root.blurConfig)
                Hypr.evalLua(root.blurConfig);
        }
    }

    Component.onCompleted: blurDelay.start()

    // Desfoque atrás dos painéis do shell ("lucerna-panel-*"). O ignore_alpha
    // restringe o desfoque aos pixels quase opacos: o véu escuro atrás dos
    // painéis (no máximo 40%) e as sobras transparentes ficam de fora. Por
    // isso a opacidade dos painéis não desce de 50%.
    function blurLua(enabled: bool): string {
        return `hl.layer_rule({ match = { namespace = "^lucerna-panel-.*" }, blur = ${enabled}, ignore_alpha = 0.45 })`;
    }

    function toLua(h: var): string {
        if (!h.activeBorder)
            return "";
        const rgb = hex => `rgb(${String(hex).replace("#", "")})`;
        return `hl.config({ general = { border_size = ${h.borderSize ?? 2}, col = { active_border = "${rgb(h.activeBorder)}", inactive_border = "${rgb(h.inactiveBorder ?? h.activeBorder)}" } }, decoration = { rounding = ${h.rounding ?? 10} } })`;
    }
}
