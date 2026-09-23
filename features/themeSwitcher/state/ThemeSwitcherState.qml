pragma Singleton

import QtQuick
import Quickshell
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

    // Integração com o Hyprland
    readonly property string hyprlandConfig: Hypr.usingLua ? toLua(ThemeManager.hyprland) : ""

    onHyprlandConfigChanged: {
        if (hyprlandConfig)
            Hypr.evalLua(hyprlandConfig);
    }

    function toLua(h: var): string {
        if (!h.activeBorder)
            return "";
        const rgb = hex => `rgb(${String(hex).replace("#", "")})`;
        return `hl.config({ general = { border_size = ${h.borderSize ?? 2}, col = { active_border = "${rgb(h.activeBorder)}", inactive_border = "${rgb(h.inactiveBorder ?? h.activeBorder)}" } }, decoration = { rounding = ${h.rounding ?? 10} } })`;
    }
}
