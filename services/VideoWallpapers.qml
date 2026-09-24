pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Vídeos e GIFs como papel de parede. Cada vídeo ganha uma versão por tela
// (resolução, proporção, ajuste e fps), convertida uma vez para ser a mais
// barata de tocar ali (ver scripts/video-wallpaper.sh). As conversões vão numa
// fila, uma por vez e com prioridade baixa; o que é pedido para uma tela que
// está à mostra passa na frente do que é só preparação.
Singleton {
    id: root

    readonly property string cacheDir: Quickshell.statePath("wallpapers")
    readonly property var extensions: ["mp4", "webm", "mkv", "mov", "m4v", "gif"]

    function isVideo(path: string): bool {
        return extensions.includes(path.split(".").pop().toLowerCase());
    }

    // Recursos da máquina, lidos uma vez.
    property bool ffmpeg: false
    // A GPU decodifica H.264 (com o driver VA-API instalado).
    property bool hardwareDecode: false
    property bool probed: false

    Process {
        running: true
        command: ["sh", "-c", "command -v ffmpeg >/dev/null && echo ffmpeg; command -v vainfo >/dev/null && vainfo 2>/dev/null | grep -q 'VAProfileH264High.*VLD' && echo vaapi; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.ffmpeg = text.includes("ffmpeg");
                root.hardwareDecode = text.includes("vaapi");
                root.probed = true;
            }
        }
    }

    // Chave de uma versão: "2560x1080-c-30" (c = recortada para preencher, f = inteira).
    function keyOf(target: var): string {
        return `${Math.round(target.width)}x${Math.round(target.height)}-${target.crop === false ? "f" : "c"}-${target.fps ?? 30}`;
    }

    function parseKey(key: string): var {
        const m = /^(\d+)x(\d+)-([cf])-(\d+)$/.exec(key);
        return m ? { width: +m[1], height: +m[2], crop: m[3] === "c", fps: +m[4] } : null;
    }

    // Fila: [{ source, key, target, background }]
    property var queue: []
    property var current: null
    property real progress: 0
    readonly property bool busy: current !== null
    // Último erro por vídeo.
    property var errors: ({})

    signal ready(string source, string key, string video, string poster)
    signal failed(string source, string key, string error)

    function isQueued(source: string, key: string): bool {
        return (current?.source === source && current?.key === key) || queue.some(j => j.source === source && j.key === key);
    }

    function isPreparing(source: string): bool {
        return current?.source === source && !current.background;
    }

    // Pede uma versão. `background`: preparação sem pressa (vai para o fim da
    // fila e roda com prioridade mínima e poucos núcleos).
    function request(source: string, target: var, background: bool): void {
        const key = keyOf(target);
        if (!source || isQueued(source, key))
            return;
        const job = { source, key, target, background: background === true };
        queue = background ? queue.concat([job]) : [job].concat(queue);
        next();
    }

    // Tira da fila o que era de um vídeo que ninguém usa mais.
    function forget(source: string): void {
        queue = queue.filter(j => j.source !== source);
    }

    function next(): void {
        if (current || !queue.length)
            return;
        const job = queue[0];
        queue = queue.slice(1);
        current = job;
        progress = 0;
        const t = job.target;
        const args = [Quickshell.shellPath("services/scripts/video-wallpaper.sh"), job.source, cacheDir, String(Math.round(t.width)), String(Math.round(t.height)), String(t.fps ?? 30), t.crop === false ? "0" : "1", hardwareDecode ? "1" : "0", job.background ? "2" : "0"];
        runner.command = ["nice", "-n", job.background ? "19" : "10"].concat(args);
        runner.running = true;
    }

    function finish(): void {
        current = null;
        Qt.callLater(next);
    }

    Process {
        id: runner

        stdout: SplitParser {
            onRead: line => {
                const job = root.current;
                if (!job)
                    return;
                const [kind, ...rest] = line.split(" ");
                if (kind === "progress") {
                    root.progress = Number(rest[0]) / 100;
                } else if (kind === "done") {
                    const errs = Object.assign({}, root.errors);
                    delete errs[job.source];
                    root.errors = errs;
                    root.ready(job.source, job.key, rest.slice(0, -1).join(" "), rest[rest.length - 1]);
                    root.finish();
                } else if (kind === "error") {
                    const errs = Object.assign({}, root.errors);
                    errs[job.source] = rest.join(" ");
                    root.errors = errs;
                    root.failed(job.source, job.key, rest.join(" "));
                    root.finish();
                }
            }
        }
        onExited: code => {
            if (root.current && code !== 0) {
                const job = root.current;
                root.failed(job.source, job.key, "a conversão foi interrompida");
                root.finish();
            }
        }
    }

    // Apaga arquivos convertidos (versões que saíram de uso).
    function remove(paths: var): void {
        const files = paths.filter(p => p && p.startsWith(cacheDir + "/"));
        if (files.length)
            Quickshell.execDetached(["rm", "-f"].concat(files));
    }
}
