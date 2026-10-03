pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Áudio por aplicativo: os streams de reprodução do PipeWire (um por app com a
// saída de som aberta), com o nome e o ícone do app. O volume e o mudo ficam
// no nó (`node.audio`): a lista só muda quando um stream entra ou sai. O
// `describe` é puro: monta a lista a partir dos nós.
Singleton {
    id: root

    // Todos os streams com áudio. Só um nó rastreado tem `properties` e
    // `audio` valendo: o tracker rastreia os candidatos, e o describe filtra.
    readonly property var candidates: Pipewire.nodes.values.filter(n => n.isStream && n.audio)
    // [{ node, name, icon }]
    readonly property var list: describe(candidates)

    // Só os streams de reprodução com áudio ("Stream/Output/Audio" no
    // PipeWire): gravações, dispositivos e vídeo ficam de fora. O nome e o
    // ícone vêm do app; na falta, do próprio nó.
    function describe(nodes: var): var {
        return (nodes ?? []).filter(n => n?.isStream && n.properties?.["media.class"] === "Stream/Output/Audio" && n.audio).map(n => {
            const p = n.properties;
            return {
                node: n,
                name: p["application.name"] || p["media.name"] || n.description || n.name || "",
                icon: p["application.icon-name"] || p["application.process.binary"] || ""
            };
        });
    }

    function setVolume(node: var, value: real): void {
        if (!node?.audio)
            return;
        node.audio.muted = false;
        node.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute(node: var): void {
        if (node?.audio)
            node.audio.muted = !node.audio.muted;
    }

    // Sem rastrear o nó, as propriedades, o volume e o mudo não valem.
    PwObjectTracker {
        objects: root.candidates
    }
}
