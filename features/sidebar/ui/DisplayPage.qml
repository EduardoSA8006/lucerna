import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.sidebar.state

// Tela: brilho, luz noturna e "não apagar".
Column {
    spacing: ThemeManager.spacing.large

    SectionHeader {
        title: "Tela"
        subtitle: PowerState.hasBrightness ? `Brilho ${Math.round(PowerState.brightness * 100)}%` : "Brilho não disponível"
    }

    EmptyState {
        visible: !PowerState.hasBrightness && !PowerState.idleEnabled && !PowerState.nightLightAvailable
        icon: Icons.brightnessMedium
        text: "Nenhuma tela com brilho ajustável (é preciso o brightnessctl)"
    }

    SettingSection {
        visible: PowerState.hasBrightness
        title: "Brilho"

        SettingRow {
            wide: true
            icon: Icons.brightnessMedium
            title: "Tela integrada"

            Slider {
                width: parent.width
                from: 0.01
                to: 1
                value: PowerState.brightness
                onMoved: v => PowerState.setBrightness(v)
            }
        }
    }

    SettingSection {
        visible: PowerState.nightLightAvailable
        title: "Luz noturna"

        SettingRow {
            icon: "nightlight"
            title: "Luz noturna"
            description: PowerState.nightLightStatus

            Switch {
                checked: PowerState.nightLightOn
                onToggled: on => PowerState.setNightLight(on)
            }
        }

        SettingRow {
            wide: true
            icon: "thermostat"
            title: "Temperatura"

            Slider {
                width: parent.width
                from: 2500
                to: 6000
                stepSize: 100
                value: PowerState.nightLightTemp
                format: v => `${Math.round(v)} K`
                onMoved: v => PowerState.setNightLightTemp(v)
            }
        }
    }

    SettingSection {
        visible: PowerState.idleEnabled
        title: "Ociosidade"

        SettingRow {
            icon: "coffee"
            title: "Não apagar a tela"
            description: "Não escurece, não desliga e não bloqueia até você desligar"

            Switch {
                checked: PowerState.keepAwake
                onToggled: on => PowerState.setKeepAwake(on)
            }
        }
    }
}
