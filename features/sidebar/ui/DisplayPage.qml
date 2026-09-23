import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.sidebar.state

// Tela: brilho.
Column {
    spacing: ThemeManager.spacing.large

    SectionHeader {
        title: "Tela"
        subtitle: PowerState.hasBrightness ? `Brilho ${Math.round(PowerState.brightness * 100)}%` : "Brilho não disponível"
    }

    EmptyState {
        visible: !PowerState.hasBrightness
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
}
