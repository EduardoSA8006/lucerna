import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.dashboard.state

// Calendário do mês. As setas ou a roda do mouse trocam o mês; clicar no título volta ao atual.
Item {
    id: root

    implicitHeight: column.implicitHeight

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => OverviewState.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
    }

    Column {
        id: column

        width: parent.width
        spacing: ThemeManager.spacing.small

        Item {
            width: parent.width
            height: 28

            IconButton {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.chevronLeft
                iconSize: 18
                onClicked: OverviewState.shiftMonth(-1)
            }

            Clickable {
                anchors.centerIn: parent
                width: title.implicitWidth + ThemeManager.spacing.normal
                height: 26
                onClicked: OverviewState.resetMonth()

                Txt {
                    id: title

                    anchors.centerIn: parent
                    text: OverviewState.monthTitle
                    color: ThemeManager.colors.accent
                    font.weight: Font.DemiBold
                }
            }

            IconButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.chevronRight
                iconSize: 18
                onClicked: OverviewState.shiftMonth(1)
            }
        }

        Grid {
            id: grid

            readonly property real cell: width / 7

            width: parent.width
            columns: 7

            Repeater {
                model: OverviewState.weekdayInitials

                delegate: Txt {
                    required property string modelData

                    width: grid.cell
                    height: 22
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    faint: true
                    font.pixelSize: ThemeManager.font.small
                    font.weight: Font.DemiBold
                }
            }

            Repeater {
                model: OverviewState.calendarDays

                delegate: Item {
                    required property var modelData

                    width: grid.cell
                    height: 26

                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        radius: 13
                        color: parent.modelData.today ? ThemeManager.colors.accent : "transparent"
                    }

                    Txt {
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: parent.modelData.day
                        mono: true
                        font.pixelSize: ThemeManager.font.small + 1
                        color: parent.modelData.today ? ThemeManager.colors.accentText : parent.modelData.inMonth ? ThemeManager.colors.text : ThemeManager.colors.textFaint
                        font.weight: parent.modelData.today ? Font.Bold : Font.Normal
                    }
                }
            }
        }
    }
}
