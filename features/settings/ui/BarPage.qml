import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.settings.state

// Barra: quando ela aparece e o que mostra.
Column {
    spacing: ThemeManager.spacing.large

    SettingSection {
        title: "Visibilidade"

        SettingRow {
            icon: Icons.toolbar
            title: "Esconder automaticamente"
            description: "A barra fica escondida e aparece ao encostar o mouse no topo da tela. Desligado, ela fica fixa e as janelas começam abaixo dela"

            Switch {
                checked: SettingsState.barAutoHide
                onToggled: on => SettingsState.setBarAutoHide(on)
            }
        }

        SettingRow {
            icon: Icons.wallpaper
            title: "Sempre visível sem janelas"
            description: "Na área de trabalho vazia a barra fica à mostra, já que não cobre nada. Some quando uma janela abre"
            dimmed: !SettingsState.barAutoHide

            Switch {
                checked: SettingsState.barOnEmpty
                enabled: SettingsState.barAutoHide
                onToggled: on => SettingsState.setBarOnEmpty(on)
            }
        }

        SettingRow {
            icon: Icons.dashboard
            title: "Aparecer ao trocar de workspace"
            description: "Mostra a barra por um instante, para ver em qual workspace você está"
            dimmed: !SettingsState.barAutoHide

            Switch {
                checked: SettingsState.barPeek
                enabled: SettingsState.barAutoHide
                onToggled: on => SettingsState.setBarPeek(on)
            }
        }
    }

    SettingSection {
        title: "Itens"

        SettingRow {
            icon: Icons.calendar
            title: "Mostrar a data"
            description: "Ao lado do relógio. Sem ela, a barra fica mais curta"

            Switch {
                checked: SettingsState.barShowDate
                onToggled: on => SettingsState.setBarShowDate(on)
            }
        }
    }
}
