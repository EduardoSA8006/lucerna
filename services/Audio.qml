pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Saída de áudio padrão, via PipeWire.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
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

    // Sem rastrear o nó, volume e mudo não são atualizados.
    PwObjectTracker {
        objects: [root.sink]
    }
}
