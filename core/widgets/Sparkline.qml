import QtQuick
import QtQuick.Shapes
import qs.core.theme

// Gráfico de linha de um histórico curto, com preenchimento suave embaixo.
// A escala se ajusta ao maior valor (ou a `maxValue`, se definido).
Item {
    id: root

    property var values: []
    property real maxValue: 0
    property color color: ThemeManager.colors.accent
    readonly property real ceiling: maxValue > 0 ? maxValue : Math.max(1, ...values)

    function point(i: int, v: real): point {
        const n = Math.max(1, values.length - 1);
        return Qt.point(i / n * width, height - 2 - (v / ceiling) * (height - 4));
    }

    readonly property var points: values.map((v, i) => point(i, v))

    Shape {
        anchors.fill: parent
        visible: root.values.length > 1
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                y1: 0
                y2: root.height

                GradientStop { position: 0; color: ThemeManager.alpha(root.color, 0.28) }
                GradientStop { position: 1; color: ThemeManager.alpha(root.color, 0) }
            }

            PathPolyline {
                path: root.points.length > 1 ? [Qt.point(0, root.height), ...root.points, Qt.point(root.width, root.height)] : []
            }
        }

        ShapePath {
            strokeColor: root.color
            strokeWidth: 2
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap

            PathPolyline {
                path: root.points
            }
        }
    }
}
