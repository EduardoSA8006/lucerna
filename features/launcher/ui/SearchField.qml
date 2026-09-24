import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.launcher.state

// Campo de busca do launcher, ligado à busca do estado. As teclas que não são
// de digitar (setas, Enter, Tab…) vão para `key`, e cada estilo decide o que
// fazem.
Rectangle {
    id: root

    property string placeholder: "Buscar aplicativos e ações"
    property int textSize: ThemeManager.font.large

    signal key(var event)

    function focusInput(): void {
        input.forceActiveFocus();
    }

    implicitHeight: 48
    radius: ThemeManager.radius.normal
    color: ThemeManager.colors.raised
    border.width: input.activeFocus ? 1 : 0
    border.color: ThemeManager.alpha(ThemeManager.colors.accent, 0.5)

    Icon {
        id: searchIcon

        anchors.left: parent.left
        anchors.leftMargin: ThemeManager.spacing.normal + 2
        anchors.verticalCenter: parent.verticalCenter
        icon: Icons.magnify
        size: 22
        color: ThemeManager.colors.accent
    }

    TextInput {
        id: input

        anchors {
            left: searchIcon.right
            right: clear.left
            leftMargin: ThemeManager.spacing.normal
            rightMargin: ThemeManager.spacing.small
            verticalCenter: parent.verticalCenter
        }
        text: LauncherState.query
        color: ThemeManager.colors.text
        selectionColor: ThemeManager.alpha(ThemeManager.colors.accent, 0.35)
        selectedTextColor: ThemeManager.colors.text
        font.family: ThemeManager.font.sans
        font.pixelSize: root.textSize
        clip: true
        focus: true
        onTextEdited: LauncherState.query = text
        Keys.onPressed: event => root.key(event)

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            visible: !input.text
            text: root.placeholder
            faint: true
            font.pixelSize: root.textSize
        }
    }

    IconButton {
        id: clear

        anchors.right: parent.right
        anchors.rightMargin: ThemeManager.spacing.small
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text !== ""
        icon: "cancel"
        iconSize: 18
        onClicked: {
            LauncherState.query = "";
            input.forceActiveFocus();
        }
    }
}
