pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.config
import qs.core.panels
import qs.core.theme
import qs.core.widgets
import qs.services

// View model da tela de configurações. Tudo o que ela muda vai para a config
// (core/config): as features leem de lá, então nenhuma depende desta tela.
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("settings")
    readonly property var screen: Hypr.focusedScreen

    // Tópicos da barra lateral. `soon` marca os que ainda não têm opções.
    readonly property var topics: [
        { id: "appearance", icon: Icons.palette, label: "Aparência", description: "Tema e animações" },
        { id: "glass", icon: Icons.blur, label: "Transparência e desfoque", description: "O vidro dos painéis" },
        { id: "notifications", icon: Icons.bell, label: "Notificações", description: "Popups e não perturbe" },
        { id: "sidebar", icon: Icons.sidebar, label: "Central lateral", description: "Lado da tela" },
        { id: "bar", icon: Icons.toolbar, label: "Barra", description: "Quando aparece e o que mostra" },
        { id: "dashboard", icon: Icons.dashboard, label: "Painel superior", description: "Abas e dados", soon: true },
        { id: "power", icon: Icons.power, label: "Energia", description: "Ações e confirmações", soon: true },
        { id: "shortcuts", icon: Icons.keyboard, label: "Atalhos", description: "Teclas e comandos" },
        { id: "about", icon: Icons.info, label: "Sobre", description: "Versões e sistema" }
    ]
    readonly property int currentIndex: Math.max(0, topics.findIndex(t => t.id === Config.settingsTopic))
    readonly property var current: topics[currentIndex]

    function close(): void {
        Panels.close();
    }

    function setTopic(index: int): void {
        const n = topics.length;
        Config.settingsTopic = topics[(index % n + n) % n].id;
    }

    function openTopic(id: string): void {
        if (topics.some(t => t.id === id))
            Config.settingsTopic = id;
        Panels.open("settings");
    }

    // Aparência
    readonly property var themes: ThemeManager.themes
    readonly property string theme: ThemeManager.current
    readonly property var animationOptions: [
        { label: "Desligadas", value: 0 },
        { label: "Rápidas", value: 0.6 },
        { label: "Normais", value: 1 },
        { label: "Suaves", value: 1.5 }
    ]
    readonly property real animationScale: Config.animationScale >= 0 ? Config.animationScale : 1

    function applyTheme(id: string): void {
        ThemeManager.apply(id);
    }

    function setAnimationScale(value: real): void {
        Config.animationScale = value;
    }

    readonly property bool outlines: ThemeManager.outlines

    function setOutlines(on: bool): void {
        Config.outlines = on;
    }

    // Transparência e desfoque
    readonly property bool transparency: ThemeManager.transparency.enabled
    readonly property real panelOpacity: ThemeManager.transparency.base
    readonly property real cardOpacity: ThemeManager.transparency.layers
    readonly property bool blur: ThemeManager.blur.enabled
    readonly property int blurSize: ThemeManager.blur.size
    readonly property int blurPasses: ThemeManager.blur.passes
    readonly property bool glassCustomized: ThemeManager.transparency.customized || ThemeManager.blur.customized
    readonly property bool blurAvailable: Hypr.usingLua

    function setTransparency(on: bool): void {
        ThemeManager.setTransparency("enabled", on);
    }

    function setPanelOpacity(value: real): void {
        ThemeManager.setTransparency("base", Math.round(value * 100) / 100);
    }

    function setCardOpacity(value: real): void {
        ThemeManager.setTransparency("layers", Math.round(value * 100) / 100);
    }

    function setBlur(on: bool): void {
        ThemeManager.setBlur("enabled", on);
    }

    function setBlurSize(value: real): void {
        ThemeManager.setBlur("size", Math.round(value));
    }

    function setBlurPasses(value: real): void {
        ThemeManager.setBlur("passes", Math.round(value));
    }

    function resetGlass(): void {
        ThemeManager.resetGlass();
    }

    // Barra
    readonly property bool barAutoHide: Config.barAutoHide
    readonly property bool barPeek: Config.barPeek
    readonly property bool barShowDate: Config.barShowDate
    readonly property bool barOnEmpty: Config.barOnEmpty

    function setBarOnEmpty(on: bool): void {
        Config.barOnEmpty = on;
    }

    function setBarAutoHide(on: bool): void {
        Config.barAutoHide = on;
    }

    function setBarPeek(on: bool): void {
        Config.barPeek = on;
    }

    function setBarShowDate(on: bool): void {
        Config.barShowDate = on;
    }

    // Central lateral
    readonly property string sidebarSide: Config.sidebarSide

    function setSidebarSide(side: string): void {
        Config.sidebarSide = side;
    }

    function previewSidebar(): void {
        Panels.openSidebar(Config.sidebarSection);
    }

    // Notificações
    readonly property bool doNotDisturb: Config.doNotDisturb
    readonly property real notificationSeconds: Config.notificationTimeout / 1000

    function setDoNotDisturb(on: bool): void {
        Config.doNotDisturb = on;
    }

    function setNotificationSeconds(seconds: real): void {
        Config.notificationTimeout = Math.round(seconds) * 1000;
    }

    function testNotification(): void {
        Quickshell.execDetached(["notify-send", "-a", "Lucerna", "Notificação de teste", `Ela some em ${Math.round(notificationSeconds)} s.`]);
    }

    // Atalhos (referência; o dev/hyprland.lua usa Alt, o README sugere Super)
    readonly property var shortcuts: [
        { keys: "Mod + Espaço", action: "Launcher", command: "panels toggle launcher" },
        { keys: "Mod + D", action: "Painel superior", command: "panels toggle dashboard" },
        { keys: "Mod + S", action: "Configurações", command: "panels toggle settings" },
        { keys: "Mod + N", action: "Avisos (central lateral)", command: "sidebar toggle notifications" },
        { keys: "Mod + C", action: "Central lateral", command: "sidebar toggle" },
        { keys: "Mod + T", action: "Seletor de temas", command: "panels toggle themes" },
        { keys: "Mod + Esc", action: "Menu de energia", command: "panels toggle power" },
        { keys: "Mod + L", action: "Bloquear a tela", command: "session lock" },
        { keys: "Brilho ↑ / ↓", action: "Brilho", command: "brightness up / down" }
    ]

    // Sobre
    readonly property var about: [
        { label: "Hyprland", value: Hypr.version || "—" },
        { label: "Quickshell", value: SystemStats.quickshellVersion || "—" },
        { label: "Sistema", value: SystemStats.osName || "—" },
        { label: "Kernel", value: SystemStats.kernel || "—" },
        { label: "Máquina", value: SystemStats.hostname || "—" }
    ]

    IpcHandler {
        target: "settings"

        // Abre num tópico: appearance, glass, notifications, shortcuts, about...
        function open(topic: string): void {
            root.openTopic(topic);
        }
    }
}
