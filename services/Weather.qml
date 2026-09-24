pragma Singleton

import QtQuick
import Quickshell

// Previsão do tempo pela Open-Meteo (open-meteo.com): gratuita, sem chave, via
// XMLHttpRequest. A localização vem de quem usa o serviço (`location`), que
// também guarda o resultado de `search()`. Atualiza a cada 30 min enquanto `active`.
Singleton {
    id: root

    // { name, latitude, longitude } ou null
    property var location: null
    property bool active: false
    // Falso no modo offline: nenhuma requisição sai.
    property bool online: true

    property var current: null      // { temp, feels, humidity, wind, code, isDay, rainChance }
    property var hourly: []         // [{ time: Date, temp, code, isDay }] próximas 12 h
    property var daily: []          // [{ date: Date, max, min, code, rainChance }] 5 dias
    property bool loading: false
    property string error: ""
    property var updatedAt: null

    property int refreshInterval: 30 * 60 * 1000

    signal located(var location)

    function get(url: string, done: var): void {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            try {
                done(xhr.status === 200 ? JSON.parse(xhr.responseText) : null);
            } catch (e) {
                done(null);
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    // Procura a cidade pelo nome e, se achar, emite `located` e atualiza.
    function search(name: string): void {
        if (!name.trim())
            return;
        if (!online) {
            error = "Modo offline ligado";
            return;
        }
        loading = true;
        error = "";
        get(`https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(name.trim())}&count=1&language=pt&format=json`, data => {
            const r = data?.results?.[0];
            if (!r) {
                loading = false;
                error = data ? `Não encontrei "${name}"` : "Sem conexão com a Open-Meteo";
                return;
            }
            const place = [r.name, r.admin1, r.country_code].filter(x => x).join(", ");
            located({ name: place, latitude: r.latitude, longitude: r.longitude });
        });
    }

    function refresh(): void {
        if (!location || !online)
            return;
        loading = true;
        error = "";
        const params = [
            `latitude=${location.latitude}`, `longitude=${location.longitude}`,
            "current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day",
            "hourly=temperature_2m,weather_code,is_day,precipitation_probability",
            "daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max",
            "timezone=auto", "forecast_days=5"
        ].join("&");
        get(`https://api.open-meteo.com/v1/forecast?${params}`, data => {
            loading = false;
            if (!data?.current) {
                error = "Sem conexão com a Open-Meteo";
                return;
            }
            const c = data.current;
            const h = data.hourly;
            const nowIndex = Math.max(0, h.time.findIndex(t => new Date(t) > new Date(c.time)));
            current = {
                temp: c.temperature_2m,
                feels: c.apparent_temperature,
                humidity: c.relative_humidity_2m,
                wind: c.wind_speed_10m,
                code: c.weather_code,
                isDay: c.is_day === 1,
                rainChance: h.precipitation_probability?.[nowIndex] ?? 0
            };
            // A partir da próxima hora cheia.
            hourly = h.time.slice(nowIndex, nowIndex + 12).map((t, i) => ({
                time: new Date(t),
                temp: h.temperature_2m[nowIndex + i],
                code: h.weather_code[nowIndex + i],
                isDay: h.is_day[nowIndex + i] === 1
            }));
            const d = data.daily;
            daily = d.time.map((t, i) => ({
                date: new Date(`${t}T12:00:00`),
                max: d.temperature_2m_max[i],
                min: d.temperature_2m_min[i],
                code: d.weather_code[i],
                rainChance: d.precipitation_probability_max?.[i] ?? 0
            }));
            updatedAt = new Date();
        });
    }

    function isStale(): bool {
        return !updatedAt || Date.now() - updatedAt.getTime() > refreshInterval;
    }

    onLocationChanged: {
        current = null;
        hourly = [];
        daily = [];
        updatedAt = null;
        if (active)
            refresh();
    }

    onActiveChanged: {
        if (active && isStale())
            refresh();
    }

    onOnlineChanged: {
        error = "";
        if (online && active && isStale())
            refresh();
    }

    Timer {
        running: root.active && root.online && root.location !== null
        repeat: true
        interval: root.refreshInterval
        onTriggered: root.refresh()
    }
}
