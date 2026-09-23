pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Saída de áudio padrão, via PipeWire.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // Dispositivos (não fluxos de apps) de saída e de entrada.
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    function nodeName(node: var): string {
        return node?.description || node?.nickname || node?.name || "";
    }

    function setDefaultSink(node: var): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node: var): void {
        Pipewire.preferredDefaultAudioSource = node;
    }

    function setMicVolume(value: real): void {
        if (source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(1, value));
        }
    }

    function toggleMicMute(): void {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }
    readonly property bool available: (sink?.ready ?? false) && sink.audio !== null
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string deviceName: sink?.description || sink?.nickname || sink?.name || ""

    function setVolume(value: real): void {
        if (!available)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function changeVolume(delta: real): void {
        setVolume(volume + delta);
    }

    function toggleMute(): void {
        if (available)
            sink.audio.muted = !sink.audio.muted;
    }

    // Pico do que está tocando (0 a 1), para visualizadores. Só é medido
    // enquanto `monitorPeak` for verdadeiro.
    property bool monitorPeak: false
    readonly property real peak: peakMonitor.peak

    PwNodePeakMonitor {
        id: peakMonitor

        node: root.sink
        enabled: root.monitorPeak
    }

    // Sem rastrear o nó, volume e mudo não são atualizados.
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks, ...root.sources]
    }
}
