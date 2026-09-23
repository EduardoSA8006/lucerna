import QtQuick
import qs.core.theme

// Animação numérica com os tokens de movimento do Material 3.
//   Spatial*: posição e tamanho; as curvas "expressivas" passam um pouco do
//             alvo e voltam, dando o efeito de mola. Não use em algo que não
//             pode passar do limite (opacidade que esconde a janela, largura de barra).
//   Effects*: opacidade e cor, sem passar do alvo.
//   Standard/Emphasized: transições comuns; *Accel para saídas.
NumberAnimation {
    enum Type {
        Spatial,
        FastSpatial,
        SlowSpatial,
        Effects,
        FastEffects,
        SlowEffects,
        Standard,
        StandardLarge,
        StandardAccel,
        Emphasized,
        EmphasizedAccel,
        EmphasizedDecel
    }

    property int type: Anim.Spatial
    readonly property QtObject tokens: ThemeManager.anim

    duration: [tokens.spatial, tokens.fastSpatial, tokens.slowSpatial, tokens.effects, tokens.fastEffects, tokens.slowEffects, tokens.normal, tokens.large, tokens.small, tokens.normal, tokens.small, tokens.normal][type]
    easing.type: Easing.BezierSpline
    easing.bezierCurve: [tokens.spatialCurve, tokens.fastSpatialCurve, tokens.slowSpatialCurve, tokens.effectsCurve, tokens.fastEffectsCurve, tokens.slowEffectsCurve, tokens.standard, tokens.standard, tokens.standardAccel, tokens.emphasized, tokens.emphasizedAccel, tokens.emphasizedDecel][type]
}
