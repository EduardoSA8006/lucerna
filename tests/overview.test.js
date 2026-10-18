// Testes de features/dashboard/state/OverviewState: as células do calendário
// (domingos, hoje, dias de outros meses) e o cabeçalho da semana.
function run(t) {
    const O = t.OverviewState;
    const cellsOf = (y, m, start, today) => O.monthCells(new Date(y, m, 1), start, today ?? new Date(2000, 0, 1));
    const sundayIndexes = cells => cells.map((c, i) => c.sunday ? i : -1).filter(i => i >= 0);
    const inMonthDays = cells => cells.filter(c => c.inMonth).map(c => c.day);

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

    t.test("overview: fevereiro de 28 dias, semana na segunda (fev/2027)", () => {
        const cells = cellsOf(2027, 1, 1);
        t.eq(inMonthDays(cells), Array.from({ length: 28 }, (_, i) => i + 1));
        t.eq(cells[0].day, 1, "1/2/2027 é segunda: sem dias do mês anterior");
        t.eq(cells[0].inMonth, true);
        t.eq(cells.slice(28).map(c => c.day), Array.from({ length: 14 }, (_, i) => i + 1), "as duas últimas linhas são de março");
        t.eq(sundayIndexes(cells), [6, 13, 20, 27, 34, 41]);
    });

    t.test("overview: fevereiro bissexto (fev/2028)", () => {
        const cells = cellsOf(2028, 1, 0);
        t.eq(inMonthDays(cells).length, 29);
        t.eq(inMonthDays(cells)[28], 29);
        t.eq(cells[2].day, 1, "1/2/2028 é terça: começa na terceira célula");
        t.eq(cells[0].day, 30, "e a grade abre em 30/1");
        t.eq(sundayIndexes(cells), [0, 7, 14, 21, 28, 35]);
    });

    t.test("overview: mês de 31 dias", () => {
        const cells = cellsOf(2026, 11, 0);
        t.eq(inMonthDays(cells), Array.from({ length: 31 }, (_, i) => i + 1));
        t.eq(cells.length, 42);
        t.eq(cells.filter(c => c.sunday && c.inMonth).map(c => c.day), [6, 13, 20, 27]);
    });

    t.test("overview: virada para janeiro", () => {
        const cells = O.monthCells(new Date(2027, 0, 1), 0, new Date(2026, 11, 31));
        t.eq(cells[0].day, 27, "1/1/2027 é sexta: a grade abre em 27/12/2026");
        t.eq(cells.filter(c => c.today).map(c => [c.day, c.inMonth]), [[31, false]], "31/12 aparece como hoje, apagado");
        t.eq(inMonthDays(cells).length, 31);
        const dec = O.monthCells(new Date(2026, 11, 1), 0, new Date(2027, 0, 1));
        t.eq(dec.filter(c => c.today).map(c => [c.day, c.inMonth]), [[1, false]], "1/1/2027 visto de dezembro: nas últimas células, apagado");
    });

    t.test("overview: cabeçalho da semana", () => {
        const sun = O.weekdayCells(0);
        t.eq(sun.map(d => d.sunday), [true, false, false, false, false, false, false], "domingo no índice 0");
        t.eq(sun[0].initial, "D");
        const mon = O.weekdayCells(1);
        t.eq(mon.map(d => d.sunday), [false, false, false, false, false, false, true], "domingo no índice 6");
        t.eq(mon.map(d => d.initial), ["S", "T", "Q", "Q", "S", "S", "D"]);
    });
}
