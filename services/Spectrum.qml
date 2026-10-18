pragma Singleton

import QtQuick
import Quickshell
import qs.services.spectrum

// Espectro do áudio que está tocando, para visualizadores: `values` traz uma
// faixa de frequência por barra, de 0 a 1, das graves às agudas, já na escala
// de quem olha (as faixas fracas realçadas). Só roda enquanto `active` (quem
// mostra pede). O backend hoje é o cava (services/spectrum/Cava.qml); se ele
// sai, volta com recuo (1, 2, 4… s) e, depois de `maxFailures` saídas seguidas
// sem entregar quadros, `available` fica falso (quem mostra cai para outro
// visualizador) até o próximo pedido.
Singleton {
    id: root

    property bool active: false
    readonly property bool available: backend.installed && failures < maxFailures
    readonly property int bars: 32
    // [0..1] por barra; vazio parado ou entre um reinício e o primeiro quadro.
    property var values: []

    readonly property int maxFailures: 4
    // Saídas seguidas do backend sem nenhum quadro entregue.
    property int failures: 0
    // O backend entregou algum quadro desde o último início.
    property bool delivered: false

    // A escala de quem olha: a raiz realça as faixas fracas (o espectro cru
    // fica quase todo baixo).
    function shape(raw: var): var {
        return (raw ?? []).map(v => Math.sqrt(Math.max(0, Math.min(1, Number(v) || 0))));
    }

    // As falhas seguidas depois de uma saída: uma saída que entregou quadros
    // (rodou e caiu) recomeça a conta.
    function failuresAfter(failures: int, delivered: bool): int {
        return delivered ? 1 : failures + 1;
    }

    // A espera antes de tentar de novo (1, 2, 4… s); -1 desiste.
    function retryDelay(failures: int, maxFailures: int): int {
        return failures >= maxFailures ? -1 : 1000 * Math.pow(2, Math.max(0, failures - 1));
    }

    function begin(): void {
        delivered = false;
        backend.start();
    }

    onActiveChanged: {
        retry.stop();
        values = [];
        if (active) {
            failures = 0;
            begin();
        } else {
            backend.stop();
        }
    }

    Cava {
        id: backend

        bars: root.bars
        onFrame: values => {
            root.delivered = true;
            root.values = root.shape(values);
        }
        onStopped: {
            root.values = [];
            root.failures = root.failuresAfter(root.failures, root.delivered);
            const delay = root.retryDelay(root.failures, root.maxFailures);
            if (delay >= 0) {
                retry.interval = delay;
                retry.restart();
            }
        }
    }

    Timer {
        id: retry

        onTriggered: {
            if (root.active)
                root.begin();
        }
    }
}
