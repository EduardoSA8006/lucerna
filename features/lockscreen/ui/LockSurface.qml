import QtQuick
import qs.core.theme
import qs.core.widgets
import qs.features.lockscreen.state

Item {
    id: root

    Component.onCompleted: input.forceActiveFocus()

    Image {
        anchors.fill: parent
        source: ThemeManager.wallpaper ? `file://${ThemeManager.wallpaper}` : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        color: ThemeManager.alpha(ThemeManager.colors.base, 0.55)
    }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        spacing: ThemeManager.spacing.small

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: LockscreenState.time
            mono: true
            font.pixelSize: ThemeManager.font.huge * 2
            font.weight: Font.Light
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: LockscreenState.date
            muted: true
            font.pixelSize: ThemeManager.font.large
        }

        Item {
            width: 1
            height: ThemeManager.spacing.large * 2
        }

        // Campo de senha
        Rectangle {
            id: field

            anchors.horizontalCenter: parent.horizontalCenter
            width: 320
            height: 48
            radius: height / 2
            color: ThemeManager.alpha(ThemeManager.colors.surface, 0.9)
            border.width: 1
            border.color: LockscreenState.error ? ThemeManager.colors.danger : input.activeFocus ? ThemeManager.alpha(ThemeManager.colors.accent, 0.6) : ThemeManager.colors.border

            Behavior on border.color { ColorAnim {} }

            SequentialAnimation {
                id: shake

                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -10; duration: 50 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 10; duration: 70 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -6; duration: 70 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
            }

            Connections {
                target: LockscreenState

                function onFailed() {
                    input.text = "";
                    shake.restart();
                }

                function onLockedChanged() {
                    input.text = "";
                }
            }

            Icon {
                id: lockIcon

                anchors.left: parent.left
                anchors.leftMargin: ThemeManager.spacing.normal + 4
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.lock
                color: ThemeManager.colors.accent

                SequentialAnimation on opacity {
                    running: LockscreenState.busy
                    loops: Animation.Infinite
                    onStopped: lockIcon.opacity = 1

                    NumberAnimation { to: 0.3; duration: 400 }
                    NumberAnimation { to: 1; duration: 400 }
                }
            }

            TextInput {
                id: input

                anchors {
                    left: lockIcon.right
                    right: parent.right
                    leftMargin: ThemeManager.spacing.small
                    rightMargin: ThemeManager.spacing.large
                    verticalCenter: parent.verticalCenter
                }
                focus: true
                echoMode: TextInput.Password
                passwordCharacter: "●"
                enabled: !LockscreenState.busy
                color: ThemeManager.colors.text
                font.family: ThemeManager.font.sans
                font.pixelSize: ThemeManager.font.large
                font.letterSpacing: 2
                clip: true
                onAccepted: LockscreenState.submit(text)
                Keys.onEscapePressed: text = ""

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !input.text
                    text: LockscreenState.busy ? "Verificando…" : LockscreenState.user ? `Senha de ${LockscreenState.user}` : "Senha"
                    faint: true
                    font.pixelSize: ThemeManager.font.normal
                }
            }
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            height: ThemeManager.font.normal * 2
            text: LockscreenState.error
            color: ThemeManager.colors.danger
            font.pixelSize: ThemeManager.font.small
        }
    }
}
