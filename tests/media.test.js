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

    M.select(original.chosen);

    t.test("media: estado original restaurado", () => {
        t.check(M.chosen === original.chosen, "chosen");
    });
}
