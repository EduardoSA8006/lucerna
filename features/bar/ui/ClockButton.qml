import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.bar.state

// A hora (e a data), clicável: abre o painel superior.
//   stacked:  data embaixo da hora (senão, ao lado)
//   showDate: mostra a data (anima ao aparecer/sumir)
//   hints:    sinais de atenção ao lado (ponto de aviso, bateria baixa)
Clickable {
    id: root

    property bool stacked: false
    property bool showDate: BarState.showDate
    property bool hints: false

    width: clock.width + ThemeManager.spacing.normal * 2
    height: ThemeManager.barHeight - 8
    radius: height / 2
    active: BarState.openPanel === "dashboard"
    activeColor: ThemeManager.alpha(ThemeManager.colors.accent, 0.16)
    onClicked: BarState.togglePanel("dashboard")
    onHoveredChanged: BarState.clockHovered(hovered)

    Behavior on width { Anim { type: Anim.FastSpatial } }

    Row {
        id: clock

        anchors.centerIn: parent
        spacing: ThemeManager.spacing.small

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.stacked
            text: BarState.time
            mono: true
            font.weight: Font.DemiBold
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.stacked && root.showDate
            text: BarState.date
            muted: true
        }

        // Empilhado: hora em cima; a data entra embaixo com animação.
        Column {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.stacked

            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: BarState.time
                mono: true
                font.pixelSize: dateLine.open ? ThemeManager.font.normal + 1 : ThemeManager.font.large
                font.weight: Font.DemiBold
            }

            Item {
                id: dateLine

                readonly property bool open: root.showDate

                anchors.horizontalCenter: parent.horizontalCenter
                width: dateText.implicitWidth
                height: open ? dateText.implicitHeight : 0
                clip: true

                Behavior on height { Anim { type: Anim.FastSpatial } }

                Txt {
                    id: dateText

                    text: BarState.date
                    muted: true
                    opacity: dateLine.open ? 1 : 0
                    font.pixelSize: ThemeManager.font.small

                    Behavior on opacity { Anim { type: Anim.FastEffects } }
                }
            }
        }

        // Sinais de atenção. (As condições vão direto: `visible` de um filho é
        // falso enquanto o pai está escondido.)
        Row {
            readonly property bool hasNotice: BarState.notificationCount > 0 && !BarState.doNotDisturb
            readonly property bool lowBattery: BarState.batteryAvailable && BarState.batteryLow

            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            visible: root.hints && (hasNotice || lowBattery)

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: parent.hasNotice
                width: 7
                height: 7
                radius: 3.5
                color: ThemeManager.colors.accent
            }

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: parent.lowBattery
                icon: BarState.batteryIcon
                size: 16
                color: ThemeManager.colors.danger
            }
        }
    }
}
