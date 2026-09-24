pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.config
import qs.core.panels
import qs.services

// Captura de tela e gravação. O painel (Print) cobre a tela: escolhe foto ou
// vídeo e o alvo (uma área arrastando, uma janela clicando ou a tela toda).
// Confirmado, o painel some, espera o tempo escolhido e captura. A foto vai
// para a pasta e (opcional) para a área de transferência, com um aviso que
// abre o arquivo ou a pasta; a gravação para pelo mesmo atalho ou pela barra.
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("capture")
    // A tela onde o painel abriu (a do foco).
    property var screen: Hypr.focusedScreen

    readonly property bool canShoot: Capture.canShoot
    readonly property bool canRecord: Capture.canRecord
    readonly property bool recording: Capture.recording

    readonly property string mode: Config.captureMode === "record" && canRecord ? "record" : "shot"
    readonly property string target: Config.captureTarget

    readonly property var modes: [
        { label: "Foto", value: "shot", icon: "photo_camera" },
        { label: "Vídeo", value: "record", icon: "videocam" }
    ]
    readonly property var targets: [
        { label: "Área", value: "area", icon: "crop_free" },
        { label: "Janela", value: "window", icon: "select_window" },
        { label: "Tela", value: "screen", icon: "fit_screen" }
    ]
    readonly property var delays: [
        { label: "Na hora", value: 0 },
        { label: "3 s", value: 3 },
        { label: "5 s", value: 5 },
        { label: "10 s", value: 10 }
    ]
    readonly property var audios: [
        { label: "Sem som", value: "none" },
        { label: "Som do sistema", value: "system" },
        { label: "Microfone", value: "mic" }
    ]

    function setMode(value: string): void {
        Config.captureMode = value;
    }

    function setTarget(value: string): void {
        Config.captureTarget = value;
    }

    // Geometria da tela do painel, em coordenadas globais.
    readonly property var screenRect: screen ? { x: screen.x, y: screen.y, width: screen.width, height: screen.height } : { x: 0, y: 0, width: 1, height: 1 }

    // Área escolhida (global). Começa na última usada, se couber nesta tela.
    property var area: null

    function defaultArea(): var {
        const s = screenRect;
        const saved = Config.captureArea;
        if (saved && saved.x >= s.x && saved.y >= s.y && saved.x + saved.width <= s.x + s.width && saved.y + saved.height <= s.y + s.height)
            return saved;
        return { x: s.x + s.width * 0.25, y: s.y + s.height * 0.25, width: s.width * 0.5, height: s.height * 0.5 };
    }

    function setArea(rect: var): void {
        area = rect;
    }

    // Janelas visíveis nesta tela, da mais à frente para a mais atrás.
    readonly property var windows: Capture.windows.filter(w => {
        const s = screenRect;
        const cx = w.x + w.width / 2;
        const cy = w.y + w.height / 2;
        return cx >= s.x && cx < s.x + s.width && cy >= s.y && cy < s.y + s.height;
    })

    // A janela sob um ponto global (a mais à frente), ou null.
    function windowAt(gx: real, gy: real): var {
        return windows.find(w => gx >= w.x && gx < w.x + w.width && gy >= w.y && gy < w.y + w.height) ?? null;
    }

    onOpenChanged: {
        if (open) {
            screen = Hypr.focusedScreen;
            area = defaultArea();
            Capture.refreshWindows();
        }
    }

    function show(mode: string): void {
        if (mode)
            Config.captureMode = mode;
        Panels.open("capture");
    }

    function close(): void {
        pending = null;
        Panels.dismiss("capture");
    }

    // Confirmar: `region` é uma região global ou o nome de uma saída.
    property var pending: null

    function confirm(region: var): void {
        if (!region)
            return;
        if (typeof region !== "string" && target === "area")
            Config.captureArea = region;
        pending = { mode, region };
        Panels.dismiss("capture");
    }

    function confirmCurrent(): void {
        confirm(target === "screen" ? screen?.name : target === "area" ? area : null);
    }

    // O painel avisa quando sumiu da tela; aí conta a espera e captura.
    function overlayHidden(): void {
        if (!pending)
            return;
        wait.interval = Math.max(60, Config.captureDelay * 1000);
        wait.restart();
    }

    Timer {
        id: wait

        onTriggered: {
            const p = root.pending;
            root.pending = null;
            if (p)
                root.run(p.mode, p.region);
        }
    }

    function stamp(): string {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd HH-mm-ss");
    }

    readonly property string shotFolder: Config.captureFolder || `${Capture.picturesDir}/Capturas de tela`
    readonly property string recordFolder: Config.recordFolder || `${Capture.videosDir}/Gravações de tela`

    function run(mode: string, region: var): void {
        if (mode === "record")
            Capture.startRecording(region, Config.captureAudio, Config.captureFps, `${recordFolder}/Gravação de tela de ${stamp()}.mp4`);
        else
            Capture.shoot(region, Config.captureCursor, `${shotFolder}/Captura de tela de ${stamp()}.png`);
    }

    // Atalhos diretos, sem o painel.
    function shootScreen(): void {
        const s = Hypr.focusedScreen;
        if (s)
            Capture.shoot(s.name, Config.captureCursor, `${shotFolder}/Captura de tela de ${stamp()}.png`);
    }

    property bool wantActiveWindow: false

    function shootWindow(): void {
        wantActiveWindow = true;
        Capture.refreshWindows();
    }

    Connections {
        target: Capture

        function onWindowsChanged() {
            if (!root.wantActiveWindow)
                return;
            root.wantActiveWindow = false;
            const w = Capture.windows[0];
            if (w)
                Capture.shoot(w, Config.captureCursor, `${root.shotFolder}/Captura de tela de ${root.stamp()}.png`);
        }

        function onShot(path: string, ok: bool) {
            if (!ok) {
                Capture.notify("", "A captura falhou", "O grim não conseguiu capturar a tela", "", []);
                return;
            }
            if (Config.captureCopy)
                Capture.copyImage(path);
            Capture.notify(path, "Captura de tela salva", Config.captureCopy ? "Também está na área de transferência" : path.split("/").pop(), path, [
                { id: "open", label: "Abrir" },
                { id: "folder", label: "Mostrar na pasta" }
            ]);
        }

        function onRecorded(path: string, ok: bool) {
            if (!ok) {
                Capture.notify("", "A gravação falhou", "O wf-recorder não gravou nada", "", []);
                return;
            }
            Capture.notify(path, "Gravação salva", path.split("/").pop(), "", [
                { id: "open", label: "Assistir" },
                { id: "folder", label: "Mostrar na pasta" }
            ]);
        }

        function onNotified(tag: string, action: string) {
            if (!tag)
                return;
            if (action === "open")
                Capture.open(tag);
            else if (action === "folder")
                Capture.reveal(tag);
        }
    }

    // Gravar ou parar (mesmo atalho).
    function toggleRecording(): void {
        if (Capture.recording)
            Capture.stopRecording();
        else
            show("record");
    }

    IpcHandler {
        target: "capture"

        // Abre o painel: "shot" ou "record" ("" = o último).
        function open(mode: string): void {
            root.show(mode);
        }

        function screen(): void {
            root.shootScreen();
        }

        function window(): void {
            root.shootWindow();
        }

        function record(): void {
            root.toggleRecording();
        }

        function stop(): void {
            Capture.stopRecording();
        }
    }
}
