pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Preferências do usuário, persistidas em ~/.local/state/quickshell/.../config.json.
// Qualquer alteração numa propriedade é gravada no disco automaticamente.
Singleton {
    id: root

    property alias theme: adapter.theme
    property alias doNotDisturb: adapter.doNotDisturb
    property alias dashboardTab: adapter.dashboardTab
    property alias weatherLocation: adapter.weatherLocation
    property alias transparencyOverride: adapter.transparencyOverride
    property alias blurOverride: adapter.blurOverride
    property alias animationScale: adapter.animationScale
    property alias notificationTimeout: adapter.notificationTimeout
    property alias settingsTopic: adapter.settingsTopic
    property alias outlines: adapter.outlines

    FileView {
        path: Quickshell.statePath("config.json")
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter

            property string theme: "nebulosa"
            property bool doNotDisturb: false
            property string dashboardTab: "overview"
            // { name, latitude, longitude } da cidade escolhida na aba Clima
            property var weatherLocation: null
            // Ajustes do usuário por cima do tema; null = seguir o tema.
            //   transparencyOverride: { enabled, base, layers }
            //   blurOverride: { enabled, size, passes }
            property var transparencyOverride: null
            property var blurOverride: null
            // Velocidade das animações; negativo = seguir o tema.
            property real animationScale: -1
            // Tempo padrão dos popups de notificação, em ms.
            property int notificationTimeout: 5000
            property string settingsTopic: "glass"
            // Contorno nos cartões; null = seguir o tema.
            property var outlines: null
        }
    }
}
