import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.settings.state

// Painéis: quais podem ficar abertos ao mesmo tempo e se desviam uns dos outros.
Column {
    spacing: ThemeManager.spacing.large

    SettingSection {
        title: "Abrir juntos"

        Repeater {
            model: SettingsState.companionOptions

            delegate: SettingRow {
                id: row

                required property var modelData

                icon: modelData.icon
                title: modelData.label
                description: modelData.description

                Switch {
                    checked: SettingsState.panelsTogether.includes(row.modelData.id)
                    onToggled: on => SettingsState.setTogether(row.modelData.id, on)
                }
            }
        }
    }

    Txt {
        width: parent.width
        wrapMode: Text.Wrap
        text: "Os ligados ficam abertos ao mesmo tempo: abrir um não fecha o outro, e a barra continua clicável. Um desligado abre sozinho e fecha os demais. Abrir as configurações fecha os dois, mas abertos depois eles ficam por cima delas. O launcher, os temas e o menu de energia sempre abrem sozinhos."
        faint: true
        font.pixelSize: ThemeManager.font.small
    }

    SettingSection {
        title: "Posição"

        SettingRow {
            icon: Icons.overlap
            title: "Ajustar para não sobrepor"
            description: "Aberto junto com a central lateral, o painel superior se afasta dela"

            Switch {
                checked: SettingsState.avoidOverlap
                onToggled: on => SettingsState.setAvoidOverlap(on)
            }
        }
    }
}
