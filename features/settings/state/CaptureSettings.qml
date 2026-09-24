pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import qs.services

// View model de Configurações → Captura de tela. A captura mora na feature
// capture; aqui ficam as preferências e as pastas.
Singleton {
    readonly property bool canShoot: Capture.canShoot
    readonly property bool canRecord: Capture.canRecord
    readonly property bool gpuEncode: Capture.vaapiEncode
    readonly property string shotFolder: Config.captureFolder || `${Capture.picturesDir}/Capturas de tela`
    readonly property string recordFolder: Config.recordFolder || `${Capture.videosDir}/Gravações de tela`
    readonly property var fpsOptions: [{ label: "30 fps", value: 30 }, { label: "60 fps", value: 60 }]
    readonly property var audioOptions: [
        { label: "Sem som", value: "none" },
        { label: "Som do sistema", value: "system" },
        { label: "Microfone", value: "mic" }
    ]

    function openFolder(path: string): void {
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$1" && xdg-open "$1"', "sh", path]);
    }
}
