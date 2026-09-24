pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.config
import qs.core.theme
import qs.services

// View model de Configurações → Papel de parede. Tudo vai para a config; a
// feature wallpaper lê de lá. O papel é por tema: cada um pode usar o seu
// próprio, só a imagem dele parada, um dos efeitos animados (nas cores do
// tema), uma imagem do usuário ou um vídeo/GIF (convertido na escolha para a
// versão mais leve de tocar naquela tela, em services/VideoWallpapers).
Singleton {
    id: root

    // Tema sendo editado (começa no ativo ao abrir a página).
    property string theme: ThemeManager.current

    function startEditing(): void {
        theme = ThemeManager.current;
        browsing = false;
    }

    readonly property var themeOptions: ThemeManager.themes.map(t => ({ label: t.name, detail: t.id === ThemeManager.current ? "Tema ativo" : "", value: t.id }))
    readonly property var themeInfo: ThemeManager.themes.find(t => t.id === theme) ?? null
    readonly property var colors: themeInfo?.colors ?? {}
    readonly property var chosen: ThemeManager.wallpaperFor(theme)

    // As opções mostradas como cartões.
    readonly property var options: {
        const own = themeInfo ?? {};
        const list = [];
        if (own.shader)
            list.push({ key: "theme", kind: "theme", label: "Padrão do tema", detail: "Animado", static: own.static, shader: own.shader });
        list.push({ key: "theme-image", kind: own.shader ? "theme-image" : "theme", label: own.shader ? "Imagem do tema" : "Padrão do tema", detail: "Parada", static: own.static, shader: "" });
        for (const e of ThemeManager.effects) {
            if (e.shader !== own.shader)
                list.push({ key: `effect:${e.id}`, kind: "effect", effect: e.id, label: e.name, detail: e.description, static: own.static, shader: e.shader });
        }
        return list;
    }

    readonly property string chosenKey: {
        if (chosen.kind === "effect")
            return chosen.shader === themeInfo?.shader ? "theme" : `effect:${chosen.effect}`;
        if (chosen.kind === "image" || chosen.kind === "video")
            return "image";
        if (chosen.kind === "theme-image")
            return themeInfo?.shader ? "theme-image" : "theme";
        return "theme";
    }

    function choose(option: var): void {
        const all = Object.assign({}, Config.themeWallpapers ?? {});
        if (option.kind === "theme")
            delete all[theme];
        else if (option.kind === "theme-image")
            all[theme] = { kind: "theme-image" };
        else if (option.kind === "effect")
            all[theme] = { kind: "effect", effect: option.effect };
        Config.themeWallpapers = all;
    }

    function chooseImage(path: string): void {
        browsing = false;
        if (VideoWallpapers.isVideo(path)) {
            prepareVideo(theme, path);
            return;
        }
        const all = Object.assign({}, Config.themeWallpapers ?? {});
        all[theme] = { kind: "image", image: path };
        Config.themeWallpapers = all;
    }

    readonly property bool usesImage: chosen.kind === "image" || chosen.kind === "video"
    readonly property bool usesVideo: chosen.kind === "video"
    readonly property string image: usesImage ? chosen.static : ""
    readonly property string sourceName: (usesVideo ? chosen.source ?? "" : image).replace(/^.*\//, "")

    // Vídeo ou GIF: o tema guarda só o original; cada tela ganha a sua versão
    // (feita pelo wallpaper). Aqui já se pedem as das telas conectadas, para o
    // vídeo ficar pronto mesmo num tema que não é o ativo.
    function prepareVideo(themeId: string, path: string): void {
        const all = Object.assign({}, Config.themeWallpapers ?? {});
        all[themeId] = { kind: "video", source: path };
        Config.themeWallpapers = all;
        const seen = {};
        for (const screen of Quickshell.screens) {
            const ratio = screen.devicePixelRatio || 1;
            const target = { width: Math.round(screen.width * ratio), height: Math.round(screen.height * ratio), crop: Config.wallpaperFill !== "fit", fps: Config.wallpaperFps };
            const key = VideoWallpapers.keyOf(target);
            if (seen[key])
                continue;
            seen[key] = true;
            VideoWallpapers.request(path, target, false);
        }
    }

    readonly property string videoSource: usesVideo ? chosen.source ?? "" : ""
    readonly property bool converting: videoSource !== "" && VideoWallpapers.isPreparing(videoSource)
    readonly property real convertProgress: VideoWallpapers.progress
    readonly property string videoError: videoSource ? VideoWallpapers.errors[videoSource] ?? "" : ""
    // Versões prontas do vídeo do tema ("2560 × 1080"), para mostrar.
    readonly property var readySizes: Object.keys((Config.videoVariants ?? {})[videoSource] ?? {}).map(k => VideoWallpapers.parseKey(k)).filter(t => t).map(t => `${t.width} × ${t.height}`).filter((v, i, all) => all.indexOf(v) === i)
    readonly property int pendingCount: VideoWallpapers.queue.filter(j => j.source === videoSource).length + (VideoWallpapers.current?.source === videoSource ? 1 : 0)

    function setPrecache(on: bool): void {
        Config.wallpaperVideoPrecache = on;
    }

    readonly property bool hardwareDecode: VideoWallpapers.hardwareDecode
    readonly property bool probed: VideoWallpapers.probed
    readonly property bool canConvert: VideoWallpapers.ffmpeg

    // Seletor de imagens
    property bool browsing: false
    property string folder: Config.wallpaperFolder || places[0]?.path || Quickshell.env("HOME")
    readonly property var imageFilters: {
        const exts = ["jpg", "jpeg", "png", "webp"].concat(VideoWallpapers.ffmpeg ? VideoWallpapers.extensions : []);
        return exts.map(e => `*.${e}`).concat(exts.map(e => `*.${e.toUpperCase()}`));
    }

    function openFolder(path: string): void {
        folder = path;
        Config.wallpaperFolder = path;
    }

    function up(): void {
        const parent = folder.replace(/\/[^/]+\/?$/, "");
        openFolder(parent || "/");
    }

    // Lugares rápidos: as pastas de imagens e downloads do usuário, a pasta
    // pessoal e os papéis que vêm com o Lucerna.
    property string picturesDir: ""
    property string downloadsDir: ""
    readonly property string home: Quickshell.env("HOME")
    readonly property var places: [
        { label: "Imagens", path: picturesDir || `${home}/Pictures` },
        { label: "Downloads", path: downloadsDir || `${home}/Downloads` },
        { label: "Pasta pessoal", path: home },
        { label: "Do Lucerna", path: `${ThemeManager.directory}/wallpapers` }
    ]

    Process {
        running: true
        command: ["sh", "-c", "xdg-user-dir PICTURES; xdg-user-dir DOWNLOAD"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [pictures, downloads] = text.trim().split("\n");
                if (pictures && pictures !== root.home)
                    root.picturesDir = pictures;
                if (downloads && downloads !== root.home)
                    root.downloadsDir = downloads;
            }
        }
    }

    // Exibição
    readonly property string mode: Config.wallpaperMode
    readonly property var modeOptions: [
        { label: "Automático", value: "auto" },
        { label: "Animado", value: "animated" },
        { label: "Parado", value: "static" }
    ]

    function setMode(value: string): void {
        Config.wallpaperMode = value;
    }

    // Por monitor: modo próprio e papel de outro tema.
    readonly property var screens: Quickshell.screens.map(s => s.name)
    readonly property var monitors: Config.wallpaperMonitors ?? {}
    readonly property var monitorModeOptions: [{ label: "Como os outros", value: "" }].concat(modeOptions)
    readonly property var monitorSourceOptions: [{ label: "O do tema ativo", value: "" }].concat(ThemeManager.themes.map(t => ({ label: `O do ${t.name}`, value: t.id })))

    function setMonitor(name: string, fields: var): void {
        const all = Object.assign({}, monitors);
        const entry = Object.assign({}, all[name] ?? {}, fields);
        for (const k of Object.keys(entry)) {
            if (!entry[k])
                delete entry[k];
        }
        if (Object.keys(entry).length)
            all[name] = entry;
        else
            delete all[name];
        Config.wallpaperMonitors = all;
    }

    // Economia
    readonly property int fps: Config.wallpaperFps
    readonly property var fpsOptions: [15, 24, 30, 60].map(v => ({ label: `${v} fps`, value: v }))

    function setFps(value: int): void {
        Config.wallpaperFps = value;
    }

    function setBatteryStatic(on: bool): void {
        Config.wallpaperBatteryStatic = on;
    }

    function setStrict(on: bool): void {
        Config.wallpaperStrict = on;
    }

    function setFullRes(on: bool): void {
        Config.wallpaperFullRes = on;
    }

    function setFill(value: string): void {
        Config.wallpaperFill = value;
    }
}
