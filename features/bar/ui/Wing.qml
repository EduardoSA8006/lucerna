import QtQuick
import qs.core.widgets

// Um lado da ilha: abre crescendo (largura com mola) e revelando o conteúdo.
Item {
    id: root

    property bool open: false
    default property alias content: holder.data

    anchors.verticalCenter: parent?.verticalCenter
    height: parent?.height ?? 0
    width: open ? holder.childrenRect.width : 0
    clip: true

    Behavior on width { Anim { type: Anim.Spatial } }

    Item {
        id: holder

        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: parent.height
        opacity: root.open ? 1 : 0

        Behavior on opacity { Anim { type: root.open ? Anim.Effects : Anim.FastEffects } }
    }
}
