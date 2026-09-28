// Testes de services/Lyrics: o LRC e a linha atual (sem a LRCLIB).
function run(t) {
    const L = t.Lyrics;

    // apply() não é pura: grava lines/synced no singleton. Guarda o estado de
    // antes para restaurar no fim (a suíte roda no mesmo processo que as
    // seguintes).
    const original = {
        lines: L.lines,
        synced: L.synced
    };

    t.test("lyrics: LRC para linhas com tempo", () => {
        t.eq(L.parse("[00:01.50] Olá\n[01:02] mundo\nsem tempo\n"), [{ time: 1.5, text: "Olá" }, { time: 62, text: "mundo" }]);
    });

    t.test("lyrics: letra sincronizada e a linha atual", () => {
        L.apply({ syncedLyrics: "[00:01.00] a\n[00:03.00] b" });
        t.eq([L.synced, L.lines.length], [true, 2]);
        t.eq([L.lineAt(0.5), L.lineAt(1), L.lineAt(2.9), L.lineAt(60)], [-1, 0, 0, 1]);
    });

    t.test("lyrics: letra sem tempo e sem letra", () => {
        L.apply({ plainLyrics: "a\nb" });
        t.eq([L.synced, L.lines], [false, [{ time: -1, text: "a" }, { time: -1, text: "b" }]]);
        t.eq(L.lineAt(10), -1);
        L.apply(null);
        t.eq([L.synced, L.lines], [false, []]);
    });

    L.lines = original.lines;
    L.synced = original.synced;

    t.test("lyrics: estado original restaurado", () => {
        t.eq([L.lines, L.synced], [original.lines, original.synced]);
    });
}
