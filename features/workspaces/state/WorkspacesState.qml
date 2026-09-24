pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.panels
import qs.services

// Visão geral dos workspaces (Super+Tab): cada workspace numa miniatura, com
// as janelas no lugar em que estão. Clicar numa janela vai até ela; clicar no
// workspace vai para ele; arrastar uma janela para outro workspace a move
// (sem ir junto). Setas e Enter pelo teclado, 1–9 direto.
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("overview")
    property var screen: Hypr.focusedScreen
    property int selected: 1
    // Endereço da janela sendo arrastada ("" = nenhuma).
    property string dragging: ""

    // Os mesmos da barra (pelo menos 5), mais um vazio no fim para onde
    // arrastar uma janela.
    readonly property var ids: {
        const used = Hypr.workspaces.map(w => w.id);
        const highest = Math.max(5, Hypr.focusedWorkspaceId, ...used);
        const list = [];
        for (let i = 1; i <= highest; i++)
            list.push(i);
        if (used.includes(highest))
            list.push(highest + 1);
        return list;
    }

    readonly property int focusedId: Hypr.focusedWorkspaceId

    onOpenChanged: {
        if (open) {
            screen = Hypr.focusedScreen;
            selected = focusedId;
            Hypr.refreshToplevels();
        }
    }

    // Enquanto aberto, janelas que abrem, fecham ou mudam de lugar atualizam.
    Connections {
        target: Hypr
        enabled: root.open

        function onWindowsChanged() {
            refresh.restart();
        }
    }

    Timer {
        id: refresh

        interval: 120
        onTriggered: Hypr.refreshToplevels()
    }

    // Tamanho lógico (sem escala, já girado) do monitor de um workspace; sem
    // monitor (workspace vazio), o da tela da visão geral.
    function monitorRect(id: int): var {
        const m = Hypr.workspace(id)?.monitor?.lastIpcObject;
        if (m && m.width) {
            const turned = (m.transform ?? 0) % 2 === 1;
            const w = (turned ? m.height : m.width) / (m.scale || 1);
            const h = (turned ? m.width : m.height) / (m.scale || 1);
            return { x: m.x, y: m.y, width: w, height: h };
        }
        const s = screen;
        return s ? { x: s.x, y: s.y, width: s.width, height: s.height } : { x: 0, y: 0, width: 1920, height: 1080 };
    }

    // Janelas de um workspace, da mais atrás para a mais à frente, com a
    // posição relativa ao monitor: [{ address, title, cls, x, y, width,
    // height, toplevel, focused }].
    function windowsOf(id: int): var {
        const origin = monitorRect(id);
        return Hypr.toplevels
            .filter(t => t.workspace?.id === id && t.lastIpcObject?.at)
            .map(t => {
                const o = t.lastIpcObject;
                return {
                    address: t.address,
                    title: t.title,
                    cls: o.class ?? "",
                    x: o.at[0] - origin.x,
                    y: o.at[1] - origin.y,
                    width: o.size[0],
                    height: o.size[1],
                    order: o.focusHistoryID ?? 0,
                    toplevel: t,
                    focused: t.address === Hypr.activeAddress
                };
            })
            .sort((a, b) => b.order - a.order);
    }

    // Fecha antes e troca logo depois: com o painel ainda pegando o teclado,
    // o Hyprland não troca de workspace.
    function go(id: int): void {
        Panels.close();
        after.run = () => Hypr.focusWorkspace(id);
        after.restart();
    }

    function focusWindow(w: var): void {
        Panels.close();
        after.run = () => Hypr.focusWindow(w.address);
        after.restart();
    }

    Timer {
        id: after

        property var run: null

        interval: 60
        onTriggered: run?.()
    }

    function moveWindow(w: var, id: int): void {
        if (w.toplevel.workspace?.id !== id) {
            Hypr.moveWindow(w.address, id);
            refresh.restart();
        }
    }

    function closeWindow(w: var): void {
        Hypr.closeWindow(w.address);
        refresh.restart();
    }

    function move(step: int): void {
        const i = ids.indexOf(selected);
        selected = ids[Math.max(0, Math.min(ids.length - 1, (i < 0 ? 0 : i) + step))];
    }

    function close(): void {
        Panels.dismiss("overview");
    }

    IpcHandler {
        target: "overview"

        function toggle(): void {
            Panels.toggle("overview");
        }
    }
}
