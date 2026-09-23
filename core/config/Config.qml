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

            property string theme: "lamparina"
            property bool doNotDisturb: false
            property string dashboardTab: "overview"
            // { name, latitude, longitude } da cidade escolhida na aba Clima
            property var weatherLocation: null
        }
    }
}
