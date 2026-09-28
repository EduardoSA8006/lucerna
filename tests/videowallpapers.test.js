// Testes de services/VideoWallpapers: extensões, chaves das versões, alvo por
// tela e a fila (sem rodar o ffmpeg).
function run(t) {
    const V = t.VideoWallpapers;

    // targetFor() lê Monitors.monitors (outro singleton, mas o teste também o
    // muta); isQueued/isPreparing só leem queue/current, porém o teste da fila
    // grava os dois diretamente e forget() grava queue. Guarda o estado de
    // antes de tudo para restaurar no fim.
    const original = {
        monitors: t.Monitors.monitors,
        queue: V.queue,
        current: V.current
    };

    t.test("videowallpapers: é vídeo ou GIF?", () => {
        t.check(V.isVideo("/a/b.MP4") && V.isVideo("x.gif"), "mp4 e gif");
        t.check(!V.isVideo("/a/b.png") && !V.isVideo("semextensão"), "imagem e sem extensão");
    });

    t.test("videowallpapers: chave da versão, ida e volta", () => {
        t.eq(V.keyOf({ width: 2560, height: 1080, crop: true, fps: 30 }), "2560x1080-c-30");
        t.eq(V.keyOf({ width: 1920.4, height: 1080, crop: false }), "1920x1080-f-30");
        t.eq(V.parseKey("2560x1080-c-60"), { width: 2560, height: 1080, crop: true, fps: 60 });
        t.eq(V.parseKey("x"), null);
    });

    t.test("videowallpapers: alvo de uma tela", () => {
        t.Monitors.monitors = [{ name: "DP-1", refresh: 59.95 }];
        t.eq(V.targetFor({ name: "DP-1", width: 1920, height: 1080, devicePixelRatio: 1.5 }, true, 60), { width: 2880, height: 1620, crop: true, fps: 60 });
        t.Monitors.monitors = [{ name: "DP-1", refresh: 50 }];
        t.eq(V.targetFor({ name: "DP-1", width: 1920, height: 1080, devicePixelRatio: 1 }, true, 60).fps, 50, "sem passar da taxa do monitor");
        t.eq(V.targetFor(null, false, 30), { width: 1920, height: 1080, crop: false, fps: 30 });
        // Arredondamento não trivial: 1923×1,25 = 2403,75 (arredonda para cima;
        // um floor pegaria 2403) e 1081×1,25 = 1351,25 (arredonda para baixo;
        // um ceil pegaria 1352). As duas frações no mesmo caso pegam uma troca
        // de Math.round por Math.floor ou por Math.ceil.
        t.Monitors.monitors = [{ name: "DP-1", refresh: 60 }];
        t.eq(V.targetFor({ name: "DP-1", width: 1923, height: 1081, devicePixelRatio: 1.25 }, true, 60), { width: 2404, height: 1351, crop: true, fps: 60 }, "arredondamento (não floor nem ceil)");
    });

    t.test("videowallpapers: fila de conversões", () => {
        V.queue = [{ source: "/v.mp4", key: "k1", target: {}, background: true }];
        V.current = { source: "/w.mp4", key: "k2", background: false };
        t.check(V.isQueued("/v.mp4", "k1") && V.isQueued("/w.mp4", "k2"), "na fila e em andamento");
        t.check(!V.isQueued("/v.mp4", "k2"), "outra versão");
        t.check(V.isPreparing("/w.mp4") && !V.isPreparing("/v.mp4"), "só o atual, e sem ser preparação");
        V.forget("/v.mp4");
        t.eq(V.queue, []);
    });

    t.Monitors.monitors = original.monitors;
    V.queue = original.queue;
    V.current = original.current;

    t.test("videowallpapers: estado original restaurado", () => {
        t.eq([t.Monitors.monitors, V.queue, V.current], [original.monitors, original.queue, original.current]);
    });
}
