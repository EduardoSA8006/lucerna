import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.theme
import qs.features.wallpaper.state

// Papel de parede em cada monitor, na camada de fundo. Na troca de tema a
// imagem nova surge por cima da antiga.
Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: window

        required property var modelData

        screen: modelData
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: ThemeManager.colors.base
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "lucerna-wallpaper"

        property string target: WallpaperState.source

        onTargetChanged: {
            back.source = front.source;
            front.opacity = 0;
            front.source = target;
        }
        Component.onCompleted: front.source = target

        Image {
            id: back

            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(window.width, window.height)
            asynchronous: true
        }

        Image {
            id: front

            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(window.width, window.height)
            asynchronous: true
            onStatusChanged: {
                if (status === Image.Ready)
                    fadeIn.restart();
            }

            NumberAnimation {
                id: fadeIn

                target: front
                property: "opacity"
                to: 1
                duration: WallpaperState.fadeDuration
                easing.type: Easing.InOutQuad
                onFinished: back.source = ""
            }
        }
    }
}
