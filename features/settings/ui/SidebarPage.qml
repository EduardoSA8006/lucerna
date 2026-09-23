import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.settings.state

// Central lateral: de que lado da tela ela abre.
Column {
    spacing: ThemeManager.spacing.large

    SettingSection {
        title: "Posição"

        SettingRow {
            icon: SettingsState.sidebarSide === "left" ? Icons.sideLeft : Icons.sideRight
            wide: true
            title: "Lado da tela"
            description: "A central entra pela borda escolhida, com as seções do lado de fora"

            SegmentedControl {
                width: parent.width
                options: [
                    { label: "Esquerda", value: "left" },
                    { label: "Direita", value: "right" }
                ]
                value: SettingsState.sidebarSide
                onSelected: v => SettingsState.setSidebarSide(v)
            }
        }
    }

    TonalButton {
        anchors.right: parent.right
        icon: Icons.sidebar
        text: "Abrir a central"
        onClicked: SettingsState.previewSidebar()
    }
}
