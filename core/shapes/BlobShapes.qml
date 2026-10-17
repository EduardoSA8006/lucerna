pragma Singleton

import QtQuick
import Quickshell

// Contas da bolha que muda de forma (core/widgets/Blob, com `morphing`): as
// formas, a curva polar que mistura duas delas e a escolha da próxima. Cada
// forma é { lobes, amplitude }, com r(θ) = raio · (1 + amplitude · cos(lobes · θ)).
Singleton {
    // As formas da sequência: lobos e amplitudes variados.
    readonly property var shapes: [
        { lobes: 5, amplitude: 0.08 },
        { lobes: 6, amplitude: 0.055 },
        { lobes: 7, amplitude: 0.07 },
        { lobes: 9, amplitude: 0.045 }
    ]

    // O raio relativo em θ = t, misturando a forma a com a b ponto a ponto:
    // m = 0 é só a, m = 1 é só b.
    function factor(a: var, b: var, m: real, t: real): real {
        return 1 + (1 - m) * a.amplitude * Math.cos(a.lobes * t) + m * b.amplitude * Math.cos(b.lobes * t);
    }

    // O contorno da mistura em steps + 1 pontos (o último fecha no primeiro),
    // centrado na caixa; o raio é dividido pelo maior fator possível (em θ = 0
    // os dois cossenos valem 1), para os lobos nunca passarem da borda.
    function outline(width: real, height: real, a: var, b: var, m: real, steps: int): var {
        const cx = width / 2, cy = height / 2;
        const r = Math.min(width, height) / 2 / factor(a, b, m, 0);
        const out = [];
        for (let i = 0; i <= steps; i++) {
            const t = i / steps * Math.PI * 2;
            const rr = r * factor(a, b, m, t);
            out.push(Qt.point(cx + rr * Math.cos(t), cy + rr * Math.sin(t)));
        }
        return out;
    }

    // A próxima forma, nunca a atual: rnd (0 a 1) escolhe entre as outras
    // count − 1. Com uma forma ou nenhuma, fica a 0.
    function next(current: int, count: int, rnd: real): int {
        if (count < 2)
            return 0;
        const k = Math.min(count - 2, Math.floor(rnd * (count - 1)));
        return k >= current ? k + 1 : k;
    }
}
