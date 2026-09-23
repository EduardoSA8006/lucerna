pragma Singleton

import QtQuick
import Quickshell

// Letras sincronizadas pela LRCLIB (lrclib.net), com o XMLHttpRequest do
// próprio QML. `lines` é [{ time (s), text }]; vazio se não houver letra.
Singleton {
    id: root

    property var lines: []
    property bool loading: false
    property bool synced: false
    property string key: ""
    property var cache: ({})

    function get(url: string, done: var): void {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            let data = null;
            if (xhr.status === 200) {
                try {
                    data = JSON.parse(xhr.responseText);
                } catch (e) {}
            }
            done(data);
        };
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", "Lucerna (https://github.com/EduardoSA8006/lucerna)");
        xhr.send();
    }

    // "[01:23.45] texto" → { time: 83.45, text: "texto" }
    function parse(lrc: string): var {
        const out = [];
        for (const line of lrc.split("\n")) {
            const m = line.match(/^\[(\d+):(\d+(?:\.\d+)?)\](.*)$/);
            if (m)
                out.push({ time: Number(m[1]) * 60 + Number(m[2]), text: m[3].trim() });
        }
        return out;
    }

    function apply(entry: var): void {
        if (entry?.syncedLyrics) {
            lines = parse(entry.syncedLyrics);
            synced = true;
        } else if (entry?.plainLyrics) {
            lines = entry.plainLyrics.split("\n").map(t => ({ time: -1, text: t.trim() }));
            synced = false;
        } else {
            lines = [];
            synced = false;
        }
    }

    // Busca a letra da faixa; chamadas repetidas para a mesma faixa não refazem a busca.
    function request(title: string, artist: string, album: string, length: real): void {
        const k = `${artist}\u0000${title}`;
        if (k === key)
            return;
        key = k;
        if (!title) {
            apply(null);
            return;
        }
        if (k in cache) {
            apply(cache[k]);
            return;
        }
        loading = true;
        lines = [];
        const q = s => encodeURIComponent(s);
        const finish = entry => {
            cache[k] = entry;
            if (key === k) {
                apply(entry);
                loading = false;
            }
        };
        const url = `https://lrclib.net/api/get?track_name=${q(title)}&artist_name=${q(artist)}&album_name=${q(album)}${length > 0 ? `&duration=${Math.round(length)}` : ""}`;
        get(url, exact => {
            if (exact?.syncedLyrics || exact?.plainLyrics)
                return finish(exact);
            get(`https://lrclib.net/api/search?track_name=${q(title)}&artist_name=${q(artist)}`, results => {
                const list = Array.isArray(results) ? results : [];
                finish(list.find(r => r.syncedLyrics) ?? list[0] ?? null);
            });
        });
    }

    // Índice da linha atual para uma posição, em segundos; -1 antes da primeira.
    function lineAt(position: real): int {
        if (!synced)
            return -1;
        let i = -1;
        while (i + 1 < lines.length && lines[i + 1].time <= position)
            i++;
        return i;
    }
}
