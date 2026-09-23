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

    // Cartão flutuante que desce do topo da tela com mola (abaixo da barra,
    // quando ela está fixa).
    Rectangle {
        id: drawer

        anchors.horizontalCenter: parent.horizontalCenter
        width: 920
        height: content.height + ThemeManager.spacing.large * 2
        y: DashboardState.topOffset - (1 - panel.progress) * (height + DashboardState.topOffset + 16)
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
