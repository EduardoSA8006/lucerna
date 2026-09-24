import QtQuick
import qs.core.theme

// Escolha numa lista longa (resoluções, taxas): um campo que mostra a opção
// atual e, ao clicar, abre a lista ali mesmo, empurrando o que vem abaixo.
// options: [{ label, value }]
Item {
    id: root

    required property var options
    property var value
    property bool expanded: false
    // Linhas visíveis antes de a lista rolar.
    property int visibleRows: 6

    signal selected(var value)

    readonly property int currentIndex: options.findIndex(o => o.value === value)
    readonly property real rowHeight: 36
    readonly property real listHeight: Math.min(options.length, visibleRows) * rowHeight

    implicitHeight: field.height + (expanded ? listHeight + ThemeManager.spacing.small : 0)
    clip: true

    Behavior on implicitHeight { Anim { type: Anim.FastSpatial } }

    Clickable {
        id: field

        width: parent.width
        height: 40
        radius: height / 2
        color: ThemeManager.alpha(ThemeManager.colors.text, 0.05)
        border.width: root.expanded ? 2 : ThemeManager.outlines ? 1 : 0
        border.color: root.expanded ? ThemeManager.colors.accent : ThemeManager.colors.border
        onClicked: root.expanded = !root.expanded

        Txt {
            anchors.left: parent.left
            anchors.leftMargin: ThemeManager.spacing.large
            anchors.right: chevron.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.options[root.currentIndex]?.label ?? "—"
            elide: Text.ElideRight
        }

        Icon {
            id: chevron

            anchors.right: parent.right
            anchors.rightMargin: ThemeManager.spacing.normal
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.expand
            size: 20
            color: ThemeManager.colors.textMuted
            rotation: root.expanded ? 180 : 0

            Behavior on rotation { Anim { type: Anim.FastSpatial } }
        }
    }

    Flickable {
        id: list

        y: field.height + ThemeManager.spacing.small
        width: parent.width
        height: root.listHeight
        contentHeight: column.height
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        visible: root.expanded || root.implicitHeight > field.height + 1

        // Abre já mostrando a opção atual.
        onVisibleChanged: {
            if (visible)
                contentY = Math.max(0, Math.min(root.currentIndex * root.rowHeight - root.rowHeight * 2, contentHeight - height));
        }

        Column {
            id: column

            width: parent.width

            Repeater {
                model: root.options

                delegate: Clickable {
                    id: option

                    required property var modelData
                    required property int index
                    readonly property bool current: index === root.currentIndex

                    width: column.width
                    height: root.rowHeight
                    radius: ThemeManager.radius.normal
                    color: current ? ThemeManager.alpha(ThemeManager.colors.accent, 0.14) : "transparent"
                    onClicked: {
                        root.expanded = false;
                        if (!current)
                            root.selected(modelData.value);
                    }

                    Txt {
                        anchors.left: parent.left
                        anchors.leftMargin: ThemeManager.spacing.large
                        anchors.verticalCenter: parent.verticalCenter
                        text: option.modelData.label
                        color: option.current ? ThemeManager.colors.accent : ThemeManager.colors.text
                        font.weight: option.current ? Font.DemiBold : Font.Normal
                    }

                    Icon {
                        anchors.right: parent.right
                        anchors.rightMargin: ThemeManager.spacing.normal
                        anchors.verticalCenter: parent.verticalCenter
                        visible: option.current
                        icon: Icons.check
                        size: 18
                        color: ThemeManager.colors.accent
                    }
                }
            }
        }
    }
}
