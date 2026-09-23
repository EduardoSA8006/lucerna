import QtQuick
import qs.core.format
import qs.core.theme
import qs.core.widgets
import qs.features.sidebar.state

// Bateria: carga, estado e perfil de energia.
Column {
    spacing: ThemeManager.spacing.large

    SectionHeader {
        title: "Bateria"
        subtitle: PowerState.status
    }

    AnimatedNumber {
        id: charge

        value: PowerState.percentage
    }

    Row {
        visible: PowerState.hasBattery
        spacing: ThemeManager.spacing.large

        CircularGauge {
            width: 132
            height: 132
            thickness: 10
            value: PowerState.percentage
            color: PowerState.charging ? ThemeManager.colors.success : PowerState.percentage < 0.15 ? ThemeManager.colors.danger : ThemeManager.colors.accent

            Column {
                anchors.centerIn: parent

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    icon: PowerState.icon
                    filled: true
                    size: 20
                    color: ThemeManager.colors.textMuted
                }

                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Format.percent(charge.shown)
                    mono: true
                    font.pixelSize: ThemeManager.font.large + 8
                    font.weight: Font.DemiBold
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: ThemeManager.spacing.small

            Repeater {
                model: [
                    { label: "Tempo", value: PowerState.remaining },
                    { label: "Consumo", value: PowerState.rate },
                    { label: "Saúde", value: PowerState.health }
                ].filter(r => r.value)

                delegate: Column {
                    required property var modelData

                    Txt {
                        text: modelData.label
                        faint: true
                        font.pixelSize: ThemeManager.font.small
                    }

                    Txt {
                        text: modelData.value
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }

    SettingSection {
        title: "Perfil de energia"

        SettingRow {
            icon: [Icons.eco, Icons.balance, Icons.rocket][PowerState.profile] ?? Icons.bolt
            wide: true
            title: "Modo"
            description: PowerState.profileDescription

            SegmentedControl {
                width: parent.width
                options: PowerState.profiles
                value: PowerState.profile
                onSelected: v => PowerState.setProfile(v)
            }
        }
    }
}
