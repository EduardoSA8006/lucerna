import QtQuick
import Quickshell
import qs.core.theme
import qs.core.widgets
import qs.features.sidebar.state

// Avisos: as notificações, não perturbe e limpar tudo.
Column {
    spacing: ThemeManager.spacing.normal

    SectionHeader {
        title: "Avisos"
        subtitle: InboxState.list.length ? `${InboxState.list.length} notificaç${InboxState.list.length > 1 ? "ões" : "ão"}` : "Nenhuma notificação"

        IconButton {
            icon: Icons.bellSleep
            active: InboxState.doNotDisturb
            onClicked: InboxState.setDoNotDisturb(!InboxState.doNotDisturb)
        }

        IconButton {
            icon: Icons.clearAll
            enabled: InboxState.list.length > 0
            onClicked: InboxState.clearAll()
        }
    }

    Txt {
        visible: InboxState.doNotDisturb
        text: "Não perturbe ligado: os popups estão escondidos"
        color: ThemeManager.colors.accent
        font.pixelSize: ThemeManager.font.small + 1
    }

    EmptyState {
        visible: InboxState.list.length === 0
        icon: Icons.bellOutline
        text: "Nada por aqui"
    }

    ListView {
        width: parent.width
        height: contentHeight
        interactive: false
        spacing: ThemeManager.spacing.small

        model: ScriptModel {
            values: InboxState.list
        }

        delegate: NotificationCard {
            required property var modelData

            width: ListView.view.width
            notification: modelData
            timeText: InboxState.timeLabel(modelData)
            onDismissRequested: InboxState.dismiss(modelData)
            onActionInvoked: action => InboxState.invoke(modelData, action)
        }

        add: Transition {
            ParallelAnimation {
                Anim { property: "x"; from: 48; to: 0; type: Anim.Spatial }
                Anim { property: "opacity"; from: 0; to: 1; type: Anim.Effects }
            }
        }

        remove: Transition {
            ParallelAnimation {
                Anim { property: "x"; to: 96; type: Anim.EmphasizedAccel }
                Anim { property: "opacity"; to: 0; type: Anim.EmphasizedAccel }
            }
        }

        displaced: Transition {
            Anim { properties: "x,y"; type: Anim.Spatial }
            Anim { property: "opacity"; to: 1; type: Anim.Effects }
        }
    }
}
