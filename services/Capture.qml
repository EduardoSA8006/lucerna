pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Captura de tela pelo grim e gravação pelo wf-recorder (os dois pelo
// screencopy do Hyprland). A região é em coordenadas globais do Hyprland
// ({ x, y, width, height }) ou uma saída inteira (nome). Também lista as
// janelas visíveis, para escolher uma.
Singleton {
    id: root

    property bool canShoot: false
    property bool canRecord: false
    // O wf-recorder codifica pela GPU (VA-API) quando dá.
    property bool vaapiEncode: false
    property string renderNode: ""
    // Som pelo PulseAudio (o pipewire-pulse) quando há; senão, direto pelo PipeWire.
    property bool pulse: false

    // Pastas padrão do usuário (xdg-user-dir), com as subpastas do Lucerna.
    property string picturesDir: `${Quickshell.env("HOME")}/Imagens`
    property string videosDir: `${Quickshell.env("HOME")}/Vídeos`

    Process {
        running: true
        command: ["sh", "-c", [
            "command -v grim >/dev/null && echo grim",
            "command -v wf-recorder >/dev/null && echo wf-recorder",
            "command -v vainfo >/dev/null && vainfo 2>/dev/null | grep -q 'VAProfileH264.*VAEntrypointEncSlice' && echo vaapi",
            "command -v pactl >/dev/null && pactl info >/dev/null 2>&1 && echo pulse",
            "for n in /dev/dri/renderD*; do [ -e \"$n\" ] && echo \"node $n\" && break; done",
            "command -v xdg-user-dir >/dev/null && echo \"pictures $(xdg-user-dir PICTURES)\" && echo \"videos $(xdg-user-dir VIDEOS)\"",
            "true"
        ].join("; ")]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                root.canShoot = lines.includes("grim");
                root.canRecord = lines.includes("wf-recorder");
                root.vaapiEncode = lines.includes("vaapi");
                root.pulse = lines.includes("pulse");
                for (const l of lines) {
                    if (l.startsWith("node "))
                        root.renderNode = l.slice(5);
                    else if (l.startsWith("pictures ") && l.length > 9)
                        root.picturesDir = l.slice(9);
                    else if (l.startsWith("videos ") && l.length > 7)
                        root.videosDir = l.slice(7);
                }
            }
        }
    }

    function geometryArg(region: var): string {
        return `${Math.round(region.x)},${Math.round(region.y)} ${Math.round(region.width)}x${Math.round(region.height)}`;
    }

    // Janelas visíveis agora (nos workspaces ativos), da mais à frente para a
    // mais atrás: [{ x, y, width, height, title, cls, monitor }].
    property var windows: []

    function refreshWindows(): void {
        windowsProbe.running = true;
    }

    Process {
        id: windowsProbe

        command: ["sh", "-c", "hyprctl monitors -j; echo '\u001e'; hyprctl clients -j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const [monitorsText, clientsText] = text.split("\u001e");
                    const monitors = JSON.parse(monitorsText);
                    const visible = new Set();
                    for (const m of monitors) {
                        visible.add(m.activeWorkspace?.id);
                        if (m.specialWorkspace?.id)
                            visible.add(m.specialWorkspace.id);
                    }
                    root.windows = JSON.parse(clientsText)
                        .filter(c => c.mapped && !c.hidden && visible.has(c.workspace?.id))
                        .sort((a, b) => a.focusHistoryID - b.focusHistoryID)
                        .map(c => ({ x: c.at[0], y: c.at[1], width: c.size[0], height: c.size[1], title: c.title, cls: c.class, monitor: c.monitor }));
                } catch (e) {
                    root.windows = [];
                }
            }
        }
    }

    // Foto: `target` é uma região ou o nome de uma saída. Emite `shot`.
    signal shot(string path, bool ok)

    function shoot(target: var, cursor: bool, path: string): void {
        const args = ["grim"];
        if (cursor)
            args.push("-c");
        if (typeof target === "string")
            args.push("-o", target);
        else
            args.push("-g", geometryArg(target));
        args.push(path);
        shooter.path = path;
        shooter.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && shift && exec "$@"', "sh", path].concat(args);
        shooter.running = true;
    }

    Process {
        id: shooter

        property string path: ""

        onExited: code => root.shot(path, code === 0)
    }

    function copyImage(path: string): void {
        Quickshell.execDetached(["sh", "-c", 'wl-copy --type image/png < "$1"', "sh", path]);
    }

    // Gravação: `audio` é "none", "system" (o que toca) ou "mic". Emite `recorded`.
    readonly property bool recording: recorder.running
    property real recordingSince: 0
    signal recorded(string path, bool ok)

    function startRecording(target: var, audio: string, fps: int, path: string): void {
        if (recorder.running)
            return;
        const args = ["wf-recorder", "-y", "-f", path, "-r", String(fps)];
        // O H.264 pede largura e altura pares.
        const even = r => ({ x: r.x, y: r.y, width: Math.max(2, Math.floor(r.width / 2) * 2), height: Math.max(2, Math.floor(r.height / 2) * 2) });
        if (typeof target === "string")
            args.push("-o", target);
        else
            args.push("-g", geometryArg(even(target)));
        // Som do sistema: o monitor da saída padrão (no PipeWire, a própria saída).
        if (audio !== "none" && !pulse)
            args.push("--audio-backend=pipewire");
        if (audio === "mic")
            args.push("--audio");
        else if (audio === "system" && pulse)
            args.push("--audio=@DEFAULT_MONITOR@");
        if (vaapiEncode && renderNode)
            args.push("-c", "h264_vaapi", "-d", renderNode);
        else
            args.push("-c", "libx264", "-p", "preset=veryfast", "-p", "crf=23");
        recorder.path = path;
        recorder.args = args;
        // No PipeWire, o som do sistema precisa do nome da saída padrão.
        if (audio === "system" && !pulse)
            sinkProbe.running = true;
        else
            recorder.launch("");
    }

    Process {
        id: sinkProbe

        command: ["wpctl", "inspect", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: recorder.launch(/node\.name = "([^"]+)"/.exec(text)?.[1] ?? "")
        }
    }

    // O wf-recorder fecha o arquivo direito com SIGINT.
    function stopRecording(): void {
        if (recorder.running)
            recorder.signal(2);
    }

    Process {
        id: recorder

        property string path: ""
        property var args: []

        function launch(sink: string): void {
            const full = sink ? args.concat([`--audio=${sink}`]) : args;
            command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && shift && exec setpriv --pdeathsig INT "$@"', "sh", path].concat(full);
            running = true;
        }

        onStarted: root.recordingSince = Date.now()
        // Parado com SIGINT, sai com 0 ou 130; o arquivo vale se tiver conteúdo.
        onExited: code => checker.check(path)
    }

    Process {
        id: checker

        property string path: ""

        function check(p: string): void {
            path = p;
            command = ["test", "-s", p];
            running = true;
        }

        onExited: code => root.recorded(path, code === 0)
    }

    // Aviso com ações; a escolhida volta em `notified` (id da ação ou "").
    signal notified(string tag, string action)

    function notify(tag: string, title: string, body: string, image: string, actions: var): void {
        const args = ["notify-send", "-a", "Lucerna", "-w"];
        if (image)
            args.push("-i", image);
        for (const a of actions)
            args.push("-A", `${a.id}=${a.label}`);
        args.push(title, body);
        const proc = notifier.createObject(root, { tag, command: args });
        proc.running = true;
    }

    Component {
        id: notifier

        Process {
            id: proc

            property string tag: ""

            stdout: StdioCollector {
                onStreamFinished: {
                    root.notified(proc.tag, text.trim());
                    proc.destroy();
                }
            }
        }
    }

    function open(path: string): void {
        Quickshell.execDetached(["xdg-open", path]);
    }

    // Abre a pasta com o arquivo selecionado, se o gerenciador de arquivos souber.
    function reveal(path: string): void {
        Quickshell.execDetached(["sh", "-c", 'dbus-send --session --dest=org.freedesktop.FileManager1 --type=method_call /org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems array:string:"file://$1" string:"" 2>/dev/null || xdg-open "$(dirname "$1")"', "sh", path]);
    }
}
