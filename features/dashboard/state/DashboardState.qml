pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.config
import qs.core.panels
import qs.core.theme
import qs.core.widgets
import qs.services

// View model do painel superior: abertura, abas e quais serviços ligar. Cada
// serviço só coleta enquanto a aba que o mostra está visível.
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("dashboard")
    readonly property var screen: Hypr.focusedScreen
    // Distância do topo: colado à borda com a barra escondida; abaixo dela quando fixa.
    readonly property real topOffset: Config.barAutoHide ? ThemeManager.spacing.small : ThemeManager.barHeight + ThemeManager.spacing.small * 2

    readonly property var tabs: [
        { id: "overview", icon: Icons.dashboard, label: "Painel" },
        { id: "media", icon: Icons.media, label: "Mídia" },
        { id: "performance", icon: Icons.performance, label: "Desempenho" },
        { id: "weather", icon: Icons.weather, label: "Clima" }
    ]
    readonly property int currentIndex: Math.max(0, tabs.findIndex(t => t.id === Config.dashboardTab))
    readonly property string current: tabs[currentIndex].id

    function close(): void {
        Panels.close();
    }

    function setTab(index: int): void {
        const count = tabs.length;
        Config.dashboardTab = tabs[(index % count + count) % count].id;
    }

    function openTab(id: string): void {
        if (tabs.some(t => t.id === id))
            Config.dashboardTab = id;
        Panels.open("dashboard");
    }

    function isShowing(id: string): bool {
        return open && current === id;
    }

    Binding {
        target: SystemStats
        property: "active"
        value: root.isShowing("overview") || root.isShowing("performance")
    }

    Binding {
        target: Media
        property: "trackPosition"
        value: root.isShowing("overview") || root.isShowing("media")
    }

    Binding {
        target: Audio
        property: "monitorPeak"
        value: root.isShowing("media")
    }

    Binding {
        target: Weather
        property: "active"
        value: root.isShowing("overview") || root.isShowing("weather")
    }

    // A cidade do clima é salva na config e repassada ao serviço.
    Binding {
        target: Weather
        property: "location"
        value: Config.weatherLocation
    }

    Connections {
        target: Weather

        function onLocated(location) {
            Config.weatherLocation = location;
        }
    }

    IpcHandler {
        target: "dashboard"

        // Abre numa aba: overview, media, performance ou weather.
        function open(tab: string): void {
            root.openTab(tab);
        }

        function toggle(): void {
            Panels.toggle("dashboard");
        }
    }
}
