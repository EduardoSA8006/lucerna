// Testes de services/VideoWallpapers: extensões, chaves das versões, alvo por
// tela e a fila (sem rodar o ffmpeg).
function run(t) {
    const V = t.VideoWallpapers;

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
        t.Monitors.monitors = [];
    });

    t.test("videowallpapers: fila de conversões", () => {
        V.queue = [{ source: "/v.mp4", key: "k1", target: {}, background: true }];
        V.current = { source: "/w.mp4", key: "k2", background: false };
        t.check(V.isQueued("/v.mp4", "k1") && V.isQueued("/w.mp4", "k2"), "na fila e em andamento");
        t.check(!V.isQueued("/v.mp4", "k2"), "outra versão");
        t.check(V.isPreparing("/w.mp4") && !V.isPreparing("/v.mp4"), "só o atual, e sem ser preparação");
        V.forget("/v.mp4");
        t.eq(V.queue, []);
        V.current = null;
    });
}
