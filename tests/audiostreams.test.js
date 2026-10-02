// Testes de services/AudioStreams: a lista de streams por aplicativo e o
// volume e o mudo de um stream. Os nós são objetos falsos; nenhuma
// propriedade do singleton é gravada.
function run(t) {
    const S = t.AudioStreams;

    // Um nó falso do PipeWire com a classe e as propriedades dadas (stream
    // quando a classe começa com "Stream/", como no PipeWire).
    function node(mediaClass, props, audio, extra) {
        return Object.assign({ name: "", description: "", isStream: mediaClass.startsWith("Stream/"), properties: Object.assign({ "media.class": mediaClass }, props), audio: audio }, extra ?? {});
    }

    t.test("audiostreams: só os streams de reprodução, com nome e ícone", () => {
        const firefox = node("Stream/Output/Audio", { "application.name": "Firefox", "application.icon-name": "firefox" }, { volume: 0.8, muted: false });
        const spotify = node("Stream/Output/Audio", { "application.name": "Spotify", "application.icon-name": "spotify" }, { volume: 0.55, muted: true });
        const recorder = node("Stream/Input/Audio", { "application.name": "OBS" }, { volume: 1, muted: false });
        const speakers = node("Audio/Sink", {}, { volume: 0.6, muted: false }, { description: "Alto-falantes" });
        const video = node("Stream/Output/Video", { "application.name": "Câmera" }, null);
        const marked = node("Stream/Output/Audio", { "application.name": "Falso" }, { volume: 1, muted: false }, { isStream: false });
        const list = S.describe([speakers, firefox, recorder, spotify, video, marked]);
        t.eq(list.map(s => [s.name, s.icon]), [["Firefox", "firefox"], ["Spotify", "spotify"]], "sem isStream, fora");
        t.eq(Object.keys(list[0]).sort(), ["icon", "name", "node"], "o volume e o mudo não vão na lista");
        t.check(list[0].node === firefox, "o nó vem junto, para o volume e o mudo");
    });

    t.test("audiostreams: nome e ícone na falta das propriedades do app", () => {
        const list = S.describe([
            node("Stream/Output/Audio", { "media.name": "Vídeo do YouTube", "application.process.binary": "chromium" }, { volume: 1, muted: false }),
            node("Stream/Output/Audio", {}, { volume: 1, muted: false }, { description: "Saída do jogo", name: "game" }),
            node("Stream/Output/Audio", {}, { volume: 1, muted: false }, { name: "alsa_playback.aplay" }),
            node("Stream/Output/Audio", {}, { volume: 1, muted: false })
        ]);
        t.eq(list.map(s => [s.name, s.icon]), [["Vídeo do YouTube", "chromium"], ["Saída do jogo", ""], ["alsa_playback.aplay", ""], ["", ""]]);
    });

    t.test("audiostreams: nós nulos e lista vazia", () => {
        const one = node("Stream/Output/Audio", { "application.name": "mpv" }, { volume: 0.3, muted: false });
        t.eq(S.describe([null, one, undefined]).map(s => s.name), ["mpv"]);
        t.eq(S.describe([]), []);
        t.eq(S.describe(null), []);
    });

    t.test("audiostreams: volume e mudo de um stream", () => {
        const audio = { volume: 0.5, muted: true };
        const stream = node("Stream/Output/Audio", {}, audio);
        S.setVolume(stream, 1.4);
        t.eq([audio.volume, audio.muted], [1, false], "mover o volume tira o mudo e limita em 1");
        S.setVolume(stream, -0.2);
        t.eq(audio.volume, 0, "limita em 0");
        S.toggleMute(stream);
        t.eq(audio.muted, true);
        S.toggleMute(stream);
        t.eq(audio.muted, false);
        S.setVolume(null, 0.5);
        S.toggleMute(node("Stream/Output/Audio", {}, null));
    });
}
