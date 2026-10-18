// Testes de services/Media: o player escolhido (sem MPRIS).
function run(t) {
    const M = t.Media;

    // select() grava chosen. Guarda o estado de antes para restaurar no fim
    // (a suíte roda no mesmo processo que as seguintes).
    const original = {
        chosen: M.chosen
    };

    t.test("media: player escolhido", () => {
        M.select(null);
        t.eq(M.chosen, null);
        const p = t.object();
        M.select(p);
        t.check(M.chosen === p, "guardado");
        t.eq(M.active, null, "sem players, nenhum ativo");
    });

    t.test("media: o próximo player, dando a volta", () => {
        const [a, b, c] = [t.object(), t.object(), t.object()];
        t.check(M.nextPlayer([a, b, c], a) === b, "a → b");
        t.check(M.nextPlayer([a, b, c], c) === a, "c → a");
        t.check(M.nextPlayer([a, b], null) === a, "sem ativo, o primeiro");
        t.eq([M.nextPlayer([], a), M.nextPlayer(null, a)], [null, null]);
        M.select(null);
        M.cycle();
        t.eq(M.chosen, null, "com menos de dois players, cycle não muda nada");
    });

    t.test("media: o álbum só quando acrescenta", () => {
        t.eq(M.albumShown("Abbey Road", "Something"), "Abbey Road");
        t.eq(M.albumShown("MONTAGEM URANIUM", "MONTAGEM URANIUM - Slowed"), "", "contido no título");
        t.eq(M.albumShown("sem controle", "SEM CONTROLE"), "", "igual, sem diferença de caixa");
        t.eq([M.albumShown("", "x"), M.albumShown("  ", "x")], ["", ""], "vazio");
    });

    M.select(original.chosen);

    t.test("media: estado original restaurado", () => {
        t.check(M.chosen === original.chosen, "chosen");
    });
}
