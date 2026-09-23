import QtQuick
import QtQuick.Shapes
import qs.core.theme

// Forma orgânica de "lobos" (tipo biscoito ou flor), desenhada com curva polar:
// r(θ) = raio · (1 + amplitude · cos(lobos · θ)). Substitui o qt6-m3shapes com
// recursos do próprio Qt. `pulse` (0 a 1) infla os lobos, para reagir ao áudio;
// `spinning` gira devagar.
Item {
    id: root

    property int lobes: 8
    property real amplitude: 0.06
    property real pulse: 0
    property color color: ThemeManager.colors.raised
    property bool spinning: false
    property real spinDuration: 24000
    readonly property int steps: 144

    property real animatedPulse: pulse

    Behavior on animatedPulse { Anim { type: Anim.FastEffects } }

    implicitWidth: 100
    implicitHeight: 100

    readonly property var points: {
        const cx = width / 2, cy = height / 2;
        const a = amplitude + animatedPulse * 0.08;
        const r = Math.min(width, height) / 2 / (1 + a);
        const out = [];
        for (let i = 0; i <= steps; i++) {
            const t = i / steps * Math.PI * 2;
            const rr = r * (1 + a * Math.cos(lobes * t));
            out.push(Qt.point(cx + rr * Math.cos(t), cy + rr * Math.sin(t)));
        }
        return out;
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
