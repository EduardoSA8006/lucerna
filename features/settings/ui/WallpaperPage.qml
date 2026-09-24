import QtQuick
import qs.core.config
import qs.core.theme
import qs.core.widgets
import qs.features.settings.state

// Papel de parede: por tema (o próprio, só a imagem, um efeito animado ou uma
// imagem sua), como exibir (automático, animado ou parado, por monitor) e as
// opções de economia do animado.
Column {
    id: page

    spacing: ThemeManager.spacing.large

    Component.onCompleted: WallpaperSettings.startEditing()

    SettingSection {
        title: "Tema"

        SettingRow {
            wide: true
            icon: Icons.palette
            title: "Papel de parede do tema"
            description: "Cada tema tem o seu. O efeito animado usa as cores do tema"

            SegmentedControl {
                width: parent.width
                options: WallpaperSettings.themeOptions
                value: WallpaperSettings.theme
                onSelected: v => {
                    WallpaperSettings.theme = v;
                    WallpaperSettings.browsing = false;
                }
            }
        }

        // Opções em cartões, dividindo a linha por igual.
        Item {
            width: parent.width
            height: options.height + ThemeManager.spacing.large * 2

            Flow {
                id: options

                readonly property int columns: Math.max(2, Math.floor((width + spacing) / (170 + spacing)))
                readonly property real cardWidth: (width - (columns - 1) * spacing) / columns

                x: ThemeManager.spacing.large
                y: ThemeManager.spacing.large
                width: parent.width - x * 2
                spacing: ThemeManager.spacing.normal

                Repeater {
                    model: WallpaperSettings.options

                    delegate: WallpaperOption {
                        required property var modelData

                        width: options.cardWidth
                        image: modelData.static ?? ""
                        shader: modelData.shader ?? ""
                        colors: WallpaperSettings.colors
                        label: modelData.label
                        detail: modelData.detail
                        selected: WallpaperSettings.chosenKey === modelData.key
                        onClicked: WallpaperSettings.choose(modelData)
                    }
                }

                // Imagem do usuário
                WallpaperOption {
                    width: options.cardWidth
                    image: WallpaperSettings.image
                    colors: WallpaperSettings.colors
                    label: WallpaperSettings.usesImage ? "Sua imagem" : "Escolher uma imagem"
                    detail: WallpaperSettings.usesImage ? WallpaperSettings.image.replace(/^.*\//, "") : "Do computador"
                    selected: WallpaperSettings.usesImage
                    onClicked: WallpaperSettings.browsing = !WallpaperSettings.browsing

                    Icon {
                        visible: !WallpaperSettings.usesImage
                        x: (parent.width - width) / 2
                        y: (parent.width * 9 / 16 + 12 - height) / 2
                        icon: "add_photo_alternate"
                        size: 30
                        color: ThemeManager.colors.accent
                    }
                }
            }
        }

        SettingRow {
            visible: WallpaperSettings.usesImage
            wide: true
            icon: Icons.resolution
            title: "Ajuste da imagem"

            SegmentedControl {
                width: parent.width
                options: [
                    { label: "Preencher (corta as bordas)", value: "crop" },
                    { label: "Inteira", value: "fit" }
                ]
                value: Config.wallpaperFill
                onSelected: v => WallpaperSettings.setFill(v)
            }
        }
    }

    ImageBrowser {
        visible: WallpaperSettings.browsing
    }

    SettingSection {
        title: "Exibição"

        SettingRow {
            wide: true
            icon: Icons.play
            title: "Animação"
            description: "Automático: anima quando o papel tem efeito e, se escolhido abaixo, só na tomada"

            SegmentedControl {
                width: parent.width
                options: WallpaperSettings.modeOptions
                value: WallpaperSettings.mode
                onSelected: v => WallpaperSettings.setMode(v)
            }
        }

        Repeater {
            model: WallpaperSettings.screens.length > 1 ? WallpaperSettings.screens : []

            delegate: SettingRow {
                id: monitorRow

                required property string modelData

                wide: true
                icon: Icons.monitor
                title: modelData

                Row {
                    width: parent.width
                    spacing: ThemeManager.spacing.small

                    Select {
                        width: (parent.width - parent.spacing) / 2
                        options: WallpaperSettings.monitorModeOptions
                        value: WallpaperSettings.monitors[monitorRow.modelData]?.mode ?? ""
                        onSelected: v => WallpaperSettings.setMonitor(monitorRow.modelData, { mode: v })
                    }

                    Select {
                        width: (parent.width - parent.spacing) / 2
                        options: WallpaperSettings.monitorSourceOptions
                        value: WallpaperSettings.monitors[monitorRow.modelData]?.source ?? ""
                        onSelected: v => WallpaperSettings.setMonitor(monitorRow.modelData, { source: v })
                    }
                }
            }
        }
    }

    SettingSection {
        title: "Economia"

        SettingRow {
            wide: true
            icon: Icons.refreshRate
            title: "Quadros por segundo"
            description: "Os efeitos são lentos: 30 já fica suave, e menos gasta menos"

            SegmentedControl {
                width: parent.width
                options: WallpaperSettings.fpsOptions
                value: WallpaperSettings.fps
                onSelected: v => WallpaperSettings.setFps(v)
            }
        }

        SettingRow {
            icon: Icons.battery[3]
            title: "Parado fora da tomada"
            description: "No automático, na bateria fica a imagem parada"
            dimmed: WallpaperSettings.mode !== "auto"

            Switch {
                checked: Config.wallpaperBatteryStatic
                onToggled: on => WallpaperSettings.setBatteryStatic(on)
            }
        }

        SettingRow {
            icon: Icons.pin
            title: "Pausar com janelas abertas"
            description: "Tela cheia e tela bloqueada sempre pausam. Ligado, qualquer janela no workspace também (sobra pouco à mostra)"

            Switch {
                checked: Config.wallpaperStrict
                onToggled: on => WallpaperSettings.setStrict(on)
            }
        }

        SettingRow {
            icon: Icons.resolution
            title: "Resolução cheia"
            description: "Desligado, o efeito é desenhado em metade da resolução e ampliado: quase igual, com um quarto do custo"

            Switch {
                checked: Config.wallpaperFullRes
                onToggled: on => WallpaperSettings.setFullRes(on)
            }
        }
    }
}
