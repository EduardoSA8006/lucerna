import QtQuick
import qs.core.theme

// A imagem do papel de parede. Na troca, a nova surge por cima da antiga.
Item {
    id: root

    property string source
    property int fillMode: Image.PreserveAspectCrop
    property int fadeDuration: 600

    onSourceChanged: {
        back.source = front.source;
        front.opacity = 0;
        front.source = source ? `file://${source}` : "";
    }
    Component.onCompleted: front.source = source ? `file://${source}` : ""

    Image {
        id: back

        anchors.fill: parent
        fillMode: root.fillMode
        sourceSize: Qt.size(root.width, root.height)
        asynchronous: true
    }

    Image {
        id: front

        anchors.fill: parent
        fillMode: root.fillMode
        sourceSize: Qt.size(root.width, root.height)
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
            duration: root.fadeDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: ThemeManager.anim.standard
            onFinished: back.source = ""
        }
    }
}
