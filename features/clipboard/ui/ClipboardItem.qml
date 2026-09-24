import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.clipboard.state

// Uma entrada do histórico: miniatura ou ícone, o texto (duas linhas), quando
// foi copiada, e os botões de fixar e apagar (no hover ou selecionada).
Clickable {
    id: root

    required property var entry
    required property bool current
    readonly property bool isImage: entry.kind === "image"

    signal chosen
    signal hoveredIn

    height: isImage ? 104 : 64
    radius: ThemeManager.radius.normal
    color: current ? ThemeManager.alpha(ThemeManager.colors.accent, 0.14) : "transparent"
    onClicked: root.chosen()
    onHoveredChanged: {
        if (hovered)
            root.hoveredIn();
    }

    Rectangle {
        id: thumb

        anchors.left: parent.left
        anchors.leftMargin: ThemeManager.spacing.normal
        anchors.verticalCenter: parent.verticalCenter
        width: root.isImage ? 136 : 36
        height: root.isImage ? 84 : 36
        radius: root.isImage ? ThemeManager.radius.small : 18
        color: root.isImage ? ThemeManager.alpha(ThemeManager.colors.text, 0.05) : ThemeManager.alpha(ThemeManager.colors.accent, root.current ? 0.22 : 0.12)
        clip: true

        Image {
            anchors.fill: parent
            visible: root.isImage
            source: root.isImage ? `file://${root.entry.path}` : ""
            sourceSize: Qt.size(272, 168)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        Icon {
            anchors.centerIn: parent
            visible: !root.isImage
            icon: "notes"
            size: 20
            color: ThemeManager.colors.accent
        }
    }

    Column {
        anchors.left: thumb.right
        anchors.leftMargin: ThemeManager.spacing.normal
        anchors.right: actions.left
        anchors.rightMargin: ThemeManager.spacing.small
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Txt {
            width: parent.width
            text: ClipboardState.preview(root.entry)
            wrapMode: Text.Wrap
            maximumLineCount: root.isImage ? 1 : 2
            elide: Text.ElideRight
            font.weight: root.current ? Font.DemiBold : Font.Normal
        }

        Row {
            spacing: 4

            Icon {
                visible: root.entry.pinned
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.pin
                filled: true
                size: 13
                color: ThemeManager.colors.accent
            }

            Txt {
                text: ClipboardState.detail(root.entry)
                faint: true
                font.pixelSize: ThemeManager.font.small
            }
        }
    }

    Row {
        id: actions

        anchors.right: parent.right
        anchors.rightMargin: ThemeManager.spacing.small
        anchors.verticalCenter: parent.verticalCenter
        opacity: root.hovered || root.current ? 1 : 0
        spacing: 2

        Behavior on opacity { Anim { type: Anim.FastEffects } }

        IconButton {
            icon: Icons.pin
            iconSize: 18
            active: root.entry.pinned
            onClicked: ClipboardState.togglePin(root.entry)
        }

        IconButton {
            icon: Icons.trash
            iconSize: 18
            onClicked: ClipboardState.remove(root.entry)
        }
    }
}
