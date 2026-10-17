import QtQuick
import qs.core.shapes
import qs.core.theme

// O relógio da bolha (Blob): a troca de forma (shapeFrom, shapeTo e a mistura
// `morph`, a cada ~6 s, em ~1,2 s) e o ângulo do giro. Cada Blob tem o seu;
// passado como `driver` a várias, elas mudam para a mesma figura e giram
// juntas. `morphing` e `spinning` falsos pausam sem mudar a forma nem o ângulo.
Item {
    id: root

    property bool morphing: false
    property bool spinning: false
    property real spinDuration: 24000

    // A mistura: de shapes[shapeFrom] (morph = 0) para shapes[shapeTo] (morph = 1).
    property int shapeFrom: 0
    property int shapeTo: 0
    property real morph: 0
    property real angle: 0

    // A troca começa da forma em que a anterior parou (shapeFrom = shapeTo e
    // morph = 0 dão a mesma curva), sem salto.
    Timer {
        interval: 6000
        running: root.morphing
        repeat: true
        onTriggered: {
            if (morphAnim.running)
                return;
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
        // Pausa com o relógio parado e segue de onde estava: as bolhas que o
        // compartilham continuam na mesma mistura.
        paused: running && !root.morphing
        duration: 1200 * ThemeManager.anim.scale
        easing.type: Easing.InOutCubic
    }

    // Pausa em vez de parar: ao voltar, segue do ângulo em que estava.
    NumberAnimation on angle {
        running: true
        paused: !root.spinning
        from: 0
        to: 360
        duration: root.spinDuration
        loops: Animation.Infinite
    }
}
