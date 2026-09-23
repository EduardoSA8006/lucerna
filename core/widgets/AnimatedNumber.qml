import QtQuick

// Número que desliza até o valor novo em vez de pular, acompanhando os
// medidores. Use `shown` para exibir (ex.: Format.percent(n.shown)).
QtObject {
    property real value: 0
    property real shown: value

    Behavior on shown { Anim { type: Anim.StandardLarge } }
}
