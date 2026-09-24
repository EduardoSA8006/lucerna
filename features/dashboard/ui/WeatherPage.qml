import QtQuick
import QtQuick.Layouts
import qs.core.theme
import qs.core.widgets
import qs.features.dashboard.state

// Aba Clima: agora, próximas horas e próximos dias. Sem cidade definida, pede uma.
Item {
    id: root

    property bool editing: false

    implicitHeight: 330

    function startEditing(): void {
        editing = true;
        search.text = "";
        search.forceActiveFocus();
    }

    function submit(): void {
        if (search.text.trim()) {
            WeatherState.search(search.text);
            editing = false;
        }
    }

    Connections {
        target: WeatherState

        function onPlaceChanged() {
            root.editing = false;
        }
    }

    // Sem cidade, o campo de busca já recebe o teclado quando a aba aparece.
    readonly property bool showing: DashboardState.isShowing("weather")
    onShowingChanged: {
        if (showing && !WeatherState.hasLocation)
            search.forceActiveFocus();
    }

    // Campo de busca da cidade: aparece sem cidade definida ou ao editar.
    Column {
        anchors.centerIn: parent
        visible: !WeatherState.hasLocation || root.editing
        spacing: ThemeManager.spacing.normal
        z: 2

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            icon: Icons.location
            filled: true
            size: 44
            color: ThemeManager.colors.accent
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Qual é a sua cidade?"
            font.pixelSize: ThemeManager.font.large
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 340
            height: 44
            radius: 22
            color: ThemeManager.colors.surface
            border.width: search.activeFocus ? 2 : ThemeManager.outlines ? 1 : 0
            border.color: search.activeFocus ? ThemeManager.colors.accent : ThemeManager.colors.border

            Behavior on border.color { ColorAnim {} }

            Icon {
                id: searchIcon

                anchors.left: parent.left
                anchors.leftMargin: ThemeManager.spacing.normal + 2
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.magnify
                size: 20
                color: ThemeManager.colors.textMuted
            }

            TextInput {
                id: search

                anchors {
                    left: searchIcon.right
                    right: parent.right
                    leftMargin: ThemeManager.spacing.small
                    rightMargin: ThemeManager.spacing.large
                    verticalCenter: parent.verticalCenter
                }
                color: ThemeManager.colors.text
                font.family: ThemeManager.font.sans
                font.pixelSize: ThemeManager.font.normal
                clip: true
                onAccepted: root.submit()
                Keys.onEscapePressed: event => {
                    if (root.editing && WeatherState.hasLocation) {
                        root.editing = false;
                        event.accepted = true;
                    } else {
                        event.accepted = false;
                    }
                }

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !search.text
                    text: "Ex.: Recife, Curitiba, Lisboa"
                    faint: true
                }
            }
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: text !== ""
            text: WeatherState.loading ? "Procurando…" : WeatherState.error
            color: WeatherState.error ? ThemeManager.colors.danger : ThemeManager.colors.textMuted
            font.pixelSize: ThemeManager.font.small
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: WeatherState.offline ? "Modo offline ligado: a busca não funciona" : "Previsão da Open-Meteo"
            faint: true
            font.pixelSize: ThemeManager.font.small
        }
    }

    RowLayout {
        anchors.fill: parent
        visible: WeatherState.hasLocation && !root.editing
        spacing: ThemeManager.spacing.normal

        // Agora
        Surface {
            Layout.preferredWidth: 320
            Layout.fillHeight: true

            Column {
                anchors.fill: parent
                anchors.margins: ThemeManager.spacing.large - 4
                spacing: ThemeManager.spacing.small

                Row {
                    width: parent.width
                    spacing: 4

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: Icons.location
                        size: 16
                        color: ThemeManager.colors.textMuted
                    }

                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 16 - 56 - 8
                        text: WeatherState.place
                        muted: true
                        font.pixelSize: ThemeManager.font.small + 1
                    }

                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: Icons.edit
                        iconSize: 16
                        onClicked: root.startEditing()
                    }

                    IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: Icons.refresh
                        iconSize: 16
                        onClicked: WeatherState.refresh()
                    }
                }

                Row {
                    spacing: ThemeManager.spacing.normal

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: WeatherState.icon
                        filled: true
                        size: 76
                        color: ThemeManager.colors.accent
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter

                        Txt {
                            text: WeatherState.temp
                            mono: true
                            font.pixelSize: ThemeManager.font.huge + 8
                            font.weight: Font.Medium
                        }

                        Txt {
                            text: WeatherState.condition
                            font.weight: Font.DemiBold
                        }

                        Txt {
                            text: WeatherState.feels
                            muted: true
                            font.pixelSize: ThemeManager.font.small + 1
                        }
                    }
                }

                Item {
                    width: 1
                    height: ThemeManager.spacing.small
                }

                Row {
                    width: parent.width

                    Repeater {
                        model: [
                            { icon: Icons.humidity, value: WeatherState.humidity, label: "Umidade" },
                            { icon: Icons.wind, value: WeatherState.wind, label: "Vento" },
                            { icon: Icons.rain, value: WeatherState.rainChance, label: "Chuva" }
                        ]

                        delegate: Column {
                            required property var modelData

                            width: parent.width / 3
                            spacing: 2

                            Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                icon: modelData.icon
                                size: 20
                                color: ThemeManager.colors.accent
                            }

                            Txt {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.value
                                mono: true
                                font.weight: Font.DemiBold
                            }

                            Txt {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                faint: true
                                font.pixelSize: ThemeManager.font.small
                            }
                        }
                    }
                }

                Txt {
                    text: WeatherState.offline ? "Modo offline: sem atualização" : WeatherState.loading ? "Atualizando…" : (WeatherState.error || WeatherState.updated)
                    color: WeatherState.error && !WeatherState.offline ? ThemeManager.colors.danger : ThemeManager.colors.textFaint
                    font.pixelSize: ThemeManager.font.small
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: ThemeManager.spacing.normal

            // Próximas horas
            Surface {
                Layout.fillWidth: true
                Layout.preferredHeight: 112

                Row {
                    anchors.fill: parent
                    anchors.margins: ThemeManager.spacing.normal

                    Repeater {
                        model: WeatherState.hourly

                        delegate: Column {
                            required property var modelData

                            width: parent.width / Math.max(1, WeatherState.hourly.length)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Txt {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.time
                                faint: true
                                font.pixelSize: ThemeManager.font.small
                            }

                            Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                icon: modelData.icon
                                size: 24
                                color: ThemeManager.colors.textMuted
                            }

                            Txt {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.temp
                                mono: true
                                font.pixelSize: ThemeManager.font.small + 1
                            }
                        }
                    }
                }
            }

            // Próximos dias
            Surface {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Column {
                    anchors.fill: parent
                    anchors.margins: ThemeManager.spacing.normal
                    spacing: 2

                    Repeater {
                        model: WeatherState.daily

                        delegate: Item {
                            required property var modelData

                            width: parent.width
                            height: 34

                            Txt {
                                id: dayName

                                anchors.verticalCenter: parent.verticalCenter
                                width: 56
                                text: modelData.day
                                font.weight: Font.DemiBold
                            }

                            Icon {
                                id: dayIcon

                                anchors.left: dayName.right
                                anchors.verticalCenter: parent.verticalCenter
                                icon: modelData.icon
                                size: 22
                                color: ThemeManager.colors.accent
                            }

                            Txt {
                                id: rain

                                anchors.left: dayIcon.right
                                anchors.leftMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                width: 40
                                text: modelData.rain
                                color: ThemeManager.colors.accent
                                font.pixelSize: ThemeManager.font.small
                            }

                            Txt {
                                id: minText

                                anchors.left: rain.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 36
                                horizontalAlignment: Text.AlignRight
                                text: modelData.min
                                mono: true
                                muted: true
                            }

                            // Faixa min–max na escala da semana.
                            Rectangle {
                                id: track

                                anchors.left: minText.right
                                anchors.right: maxText.left
                                anchors.margins: ThemeManager.spacing.normal
                                anchors.verticalCenter: parent.verticalCenter
                                height: 6
                                radius: 3
                                color: ThemeManager.colors.track

                                Rectangle {
                                    x: modelData.from * parent.width
                                    width: Math.max(parent.height, (modelData.to - modelData.from) * parent.width)
                                    height: parent.height
                                    radius: 3
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal

                                        GradientStop { position: 0; color: ThemeManager.alpha(ThemeManager.colors.accent, 0.55) }
                                        GradientStop { position: 1; color: ThemeManager.colors.accent }
                                    }
                                }
                            }

                            Txt {
                                id: maxText

                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 36
                                horizontalAlignment: Text.AlignRight
                                text: modelData.max
                                mono: true
                            }
                        }
                    }
                }
            }
        }
    }
}
