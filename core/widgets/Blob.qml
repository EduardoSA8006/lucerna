import QtQuick
import QtQuick.Shapes
import qs.core.shapes
import qs.core.theme

// Forma orgânica de "lobos" (tipo biscoito ou flor), desenhada com curva polar:
// r(θ) = raio · (1 + amplitude · cos(lobos · θ)). Substitui o qt6-m3shapes com
// recursos do próprio Qt. `pulse` (0 a 1) infla os lobos, para reagir ao áudio;
// `spinning` gira devagar. Com `morphing`, ignora `lobes` e `amplitude`: a cada
// ~6 s vira outra forma de BlobShapes.shapes, misturando as duas curvas em ~1,2 s.
Item {
    id: root

    property int lobes: 8
    property real amplitude: 0.06
    property real pulse: 0
    property color color: ThemeManager.colors.raised
    property bool spinning: false
    property real spinDuration: 24000
    property bool morphing: false
    readonly property int steps: 144

    // A mistura: de shapes[shapeFrom] (morph = 0) para shapes[shapeTo] (morph = 1).
    property int shapeFrom: 0
    property int shapeTo: 0
    property real morph: 0

    property real animatedPulse: pulse

    Behavior on animatedPulse { Anim { type: Anim.FastEffects } }

    implicitWidth: 100
    implicitHeight: 100

    readonly property var points: {
        const extra = animatedPulse * 0.08;
        const grow = s => ({ lobes: s.lobes, amplitude: s.amplitude + extra });
        const a = morphing ? BlobShapes.shapes[shapeFrom] : { lobes: lobes, amplitude: amplitude };
        const b = morphing ? BlobShapes.shapes[shapeTo] : a;
        return BlobShapes.outline(width, height, grow(a), grow(b), morph, steps);
    }

    // A troca começa da forma em que a anterior parou (shapeFrom = shapeTo e
    // morph = 0 dão a mesma curva), sem salto.
    Timer {
        interval: 6000
        running: root.morphing && root.visible
        repeat: true
        onTriggered: {
            root.shapeFrom = root.shapeTo;
            root.morph = 0;
            root.shapeTo = BlobShapes.next(root.shapeTo, BlobShapes.shapes.length, Math.random());
            morphAnim.restart();
        }
    }

    NumberAnimation {
        id: morphAnim

        target: root
        property: "morph"
        from: 0
        to: 1
        duration: 1200 * ThemeManager.anim.scale
        easing.type: Easing.InOutCubic
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillColor: root.color

            PathPolyline {
                path: root.points
            }
        }

        RotationAnimation on rotation {
            running: root.spinning && root.visible
            from: 0
            to: 360
            duration: root.spinDuration
            loops: Animation.Infinite
        }
    }
}
