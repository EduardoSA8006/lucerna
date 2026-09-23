pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.core.config

// Único ponto de verdade do visual. Carrega o tema ativo de themes/<id>.json
// e expõe os tokens; nenhum componente usa cor ou tamanho fixo.
Singleton {
    id: root

    readonly property string defaultTheme: "lamparina"
    readonly property string directory: Quickshell.shellPath("themes")
    readonly property string current: Config.theme

    // Temas disponíveis, para o seletor: { id, name, description, dark, colors, wallpaper }.
    property var themes: []

    readonly property var data: parse(activeFile.text())
    readonly property bool dark: data.dark ?? true
    readonly property string wallpaper: resolvePath(data.wallpaper ?? "")
    readonly property var hyprland: data.hyprland ?? ({})

    readonly property QtObject colors: QtObject {
        property color base: root.token("base")
        property color surface: root.token("surface")
        property color raised: root.token("raised")
        property color border: root.token("border")
        property color text: root.token("text")
        property color textMuted: root.token("textMuted")
        property color textFaint: root.token("textFaint")
        property color accent: root.token("accent")
        property color accentText: root.token("accentText")
        property color danger: root.token("danger")
        property color success: root.token("success")
        property color warning: root.token("warning")

        Behavior on base { ColorAnimation { duration: root.anim.slow } }
        Behavior on surface { ColorAnimation { duration: root.anim.slow } }
        Behavior on raised { ColorAnimation { duration: root.anim.slow } }
        Behavior on border { ColorAnimation { duration: root.anim.slow } }
        Behavior on text { ColorAnimation { duration: root.anim.slow } }
        Behavior on textMuted { ColorAnimation { duration: root.anim.slow } }
        Behavior on textFaint { ColorAnimation { duration: root.anim.slow } }
        Behavior on accent { ColorAnimation { duration: root.anim.slow } }
        Behavior on accentText { ColorAnimation { duration: root.anim.slow } }
        Behavior on danger { ColorAnimation { duration: root.anim.slow } }
        Behavior on success { ColorAnimation { duration: root.anim.slow } }
        Behavior on warning { ColorAnimation { duration: root.anim.slow } }
    }

    readonly property QtObject font: QtObject {
        readonly property string sans: root.data.font?.sans ?? "sans-serif"
        readonly property string mono: root.data.font?.mono ?? "monospace"
        readonly property string icon: root.data.font?.icon ?? "monospace"
        readonly property int small: root.data.font?.size?.small ?? 11
        readonly property int normal: root.data.font?.size?.normal ?? 13
        readonly property int large: root.data.font?.size?.large ?? 16
        readonly property int huge: root.data.font?.size?.huge ?? 44
    }

    readonly property QtObject radius: QtObject {
        readonly property int small: root.data.radius?.small ?? 6
        readonly property int normal: root.data.radius?.normal ?? 10
        readonly property int large: root.data.radius?.large ?? 16
    }

    readonly property QtObject spacing: QtObject {
        readonly property int tiny: root.data.spacing?.tiny ?? 4
        readonly property int small: root.data.spacing?.small ?? 8
        readonly property int normal: root.data.spacing?.normal ?? 12
        readonly property int large: root.data.spacing?.large ?? 20
    }

    readonly property QtObject anim: QtObject {
        readonly property int fast: root.data.animation?.fast ?? 120
        readonly property int normal: root.data.animation?.normal ?? 220
        readonly property int slow: root.data.animation?.slow ?? 420
    }

    readonly property int barHeight: data.bar?.height ?? 34

    function apply(id: string): void {
        Config.theme = id;
    }

    function token(name: string): color {
        return data.colors?.[name] ?? "#ff00ff";
    }

    // Cor com opacidade, para véus e realces: ThemeManager.alpha(colors.accent, 0.2).
    function alpha(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function parse(text: string): var {
        if (!text)
            return {};
        try {
            return JSON.parse(text);
        } catch (e) {
            console.warn("ThemeManager: JSON inválido:", e);
            return {};
        }
    }

    function resolvePath(path: string): string {
        if (!path)
            return "";
        if (path.startsWith("~/"))
            return Quickshell.env("HOME") + path.slice(1);
        if (path.startsWith("/"))
            return path;
        return `${directory}/${path}`;
    }

    function rebuildList(): void {
        const list = [];
        for (let i = 0; i < themeFiles.count; i++) {
            const file = themeFiles.objectAt(i);
            if (!file?.loaded)
                continue;
            const d = parse(file.text());
            list.push({
                id: file.themeId,
                name: d.name ?? file.themeId,
                description: d.description ?? "",
                dark: d.dark ?? true,
                colors: d.colors ?? {},
                wallpaper: resolvePath(d.wallpaper ?? "")
            });
        }
        list.sort((a, b) => a.id === defaultTheme ? -1 : b.id === defaultTheme ? 1 : a.name.localeCompare(b.name));
        themes = list;
    }

    FileView {
        id: activeFile

        path: `${root.directory}/${root.current}.json`
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: {
            console.warn(`ThemeManager: tema "${root.current}" não encontrado, voltando para "${root.defaultTheme}"`);
            if (root.current !== root.defaultTheme)
                Config.theme = root.defaultTheme;
        }
    }

    FolderListModel {
        id: folder

        folder: `file://${root.directory}`
        nameFilters: ["*.json"]
        showDirs: false
    }

    Instantiator {
        id: themeFiles

        model: folder
        onObjectAdded: root.rebuildList()
        onObjectRemoved: root.rebuildList()

        delegate: FileView {
            required property string filePath
            required property string fileBaseName
            readonly property string themeId: fileBaseName

            path: filePath
            watchChanges: true
            onFileChanged: reload()
            onLoaded: root.rebuildList()
        }
    }
}
