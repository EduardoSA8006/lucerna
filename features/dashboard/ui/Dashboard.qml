import QtQuick
import Quickshell
import qs.core.theme
import qs.core.widgets
import qs.features.dashboard.state

// Painel superior: desce de dentro da barra, com mola, e a altura acompanha a
// aba atual. Tab/Shift+Tab ou 1–4 trocam de aba; Esc ou clique fora fecham.
OverlayPanel {
    id: panel

    name: "dashboard"
    open: DashboardState.open
    screen: DashboardState.screen
    dim: 0.18
    onDismissed: DashboardState.close()

    onOpenChanged: {
        if (open)
            content.forceActiveFocus();
    }

    readonly property var pageItems: [overview, media, performance, weather]
    readonly property int index: DashboardState.currentIndex

    // Recorte logo abaixo da barra: o painel parece sair de dentro dela.
    Item {
        id: clip

        anchors.horizontalCenter: parent.horizontalCenter
        y: ThemeManager.barHeight
        width: drawer.width
        height: Math.max(0, drawer.y + drawer.height + 1)
        clip: true

        Rectangle {
            id: drawer

            // Parte escondida atrás da barra: cobre a mola quando ela passa do alvo.
            readonly property real hiddenTop: 40

            width: 920
            height: content.height + hiddenTop + ThemeManager.spacing.large
            y: -hiddenTop - (1 - panel.progress) * (height - hiddenTop + 8)
            color: ThemeManager.glass(ThemeManager.colors.base, 0)
            radius: ThemeManager.radius.large
            border.width: ThemeManager.outlines ? 1 : 0
            border.color: ThemeManager.colors.border

            FocusScope {
                id: content

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: ThemeManager.spacing.large
                    rightMargin: ThemeManager.spacing.large
                    bottomMargin: ThemeManager.spacing.large
                }
                height: tabs.height + ThemeManager.spacing.normal + pages.height
                focus: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Tab)
                        DashboardState.setTab(panel.index + 1);
                    else if (event.key === Qt.Key_Backtab)
                        DashboardState.setTab(panel.index - 1);
                    else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_4)
                        DashboardState.setTab(event.key - Qt.Key_1);
                    else
                        return;
                    event.accepted = true;
                }

                TabBar {
                    id: tabs

                    width: parent.width
                    tabs: DashboardState.tabs
                    currentIndex: panel.index
                    onActivated: index => DashboardState.setTab(index)
                }

                Item {
                    id: pages

                    anchors.top: tabs.bottom
                    anchors.topMargin: ThemeManager.spacing.normal
                    width: parent.width
                    height: panel.pageItems[panel.index].implicitHeight
                    clip: true

                    Behavior on height { Anim { type: Anim.Spatial } }


                    Row {
                        id: pagesRow

                        x: -panel.index * pages.width

                        Behavior on x { Anim { type: Anim.Spatial } }

                        OverviewPage {
                            id: overview

                            width: pages.width
                        }

                        MediaPage {
                            id: media

                            width: pages.width
                        }

                        PerformancePage {
                            id: performance

                            width: pages.width
                        }

                        WeatherPage {
                            id: weather

                            width: pages.width
                        }
                    }
                }
            }
        }
    }
}
