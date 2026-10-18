// Testes de features/dashboard/state/OverviewState: as células do calendário
// (domingos, hoje, dias de outros meses) e o cabeçalho da semana.
function run(t) {
    const O = t.OverviewState;

    t.test("overview: outubro de 2026 começando no domingo", () => {
        const cells = O.monthCells(new Date(2026, 9, 1), 0, new Date(2026, 9, 17));
        t.eq(cells.length, 42);
        t.eq(cells[0].day, 27, "1/10/2026 é quinta: a grade começa em 27/9 (domingo)");
        t.eq(cells.filter(c => c.sunday).map(c => c.day).slice(0, 5), [27, 4, 11, 18, 25]);
        t.eq(cells.every((c, i) => c.sunday === (i % 7 === 0)), true, "domingo é a primeira coluna");
        t.eq(cells.filter(c => c.today).map(c => c.day), [17]);
        t.eq(cells[0].inMonth, false, "27/9 é de outro mês");
        t.eq(cells[0].sunday, true, "e continua domingo");
    });

    t.test("overview: semana começando na segunda", () => {
        const cells = O.monthCells(new Date(2026, 9, 1), 1, new Date(2026, 9, 17));
        t.eq(cells[0].day, 28, "a grade começa na segunda, 28/9");
        t.eq(cells.every((c, i) => c.sunday === (i % 7 === 6)), true, "domingo é a última coluna");
    });

    t.test("overview: hoje fora do mês mostrado", () => {
        const cells = O.monthCells(new Date(2026, 10, 1), 0, new Date(2026, 9, 17));
        t.eq(cells.some(c => c.today), false, "novembro não mostra o dia 17/10");
        const edge = O.monthCells(new Date(2026, 11, 1), 0, new Date(2026, 10, 30));
        t.eq(edge.filter(c => c.today).map(c => [c.day, c.inMonth]), [[30, false]], "hoje no fim do mês anterior aparece, apagado");
    });
}
