pragma Singleton

import QtQuick
import Quickshell

// Contas da fila circular do seletor de temas: a volta do índice, a distância
// de um item até o centro pelo caminho mais curto e o deslocamento na tela.
Singleton {
    // Índice com volta: wrap(-1, 5) → 4, wrap(5, 5) → 0. Fila vazia dá 0.
    function wrap(i: int, n: int): int {
        return n > 0 ? ((i % n) + n) % n : 0;
    }

    // Distância com sinal do item i até o centro, pelo lado mais curto, entre
    // -n/2 (exclusive) e n/2; no empate (fila par), o lado direito.
    function offset(i: int, center: int, n: int): int {
        const d = wrap(i - center, n);
        return d > n / 2 ? d - n : d;
    }

    // Quanto o centro do item a d passos fica do centro da fila: cada passo
    // escala o item por ratio, com gap entre as bordas de um e do outro.
    function spread(d: int, size: real, gap: real, ratio: real): real {
        let x = 0;
        for (let k = 1; k <= Math.abs(d); k++)
            x += size / 2 * (Math.pow(ratio, k - 1) + Math.pow(ratio, k)) + gap;
        return d < 0 ? -x : x;
    }
}
