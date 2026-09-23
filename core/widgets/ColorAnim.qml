import QtQuick
import qs.core.theme

// Transição de cor com a curva padrão do Material 3.
ColorAnimation {
    duration: ThemeManager.anim.small
    easing.type: Easing.BezierSpline
    easing.bezierCurve: ThemeManager.anim.standard
}
