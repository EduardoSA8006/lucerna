pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.format
import qs.core.widgets
import qs.services

// View model da aba Painel: usuário, relógio, calendário e resumos.
Singleton {
    id: root

    readonly property var locale: Qt.locale("pt_BR")

    // Usuário e sistema
    readonly property string user: Quickshell.env("USER") || "você"
    readonly property string hostname: SystemStats.hostname
    // Foto do usuário em ~/.face, se existir (o mesmo arquivo que o GDM e o SDDM usam).
    readonly property string facePath: `${Quickshell.env("HOME")}/.face`
    property bool hasFace: false
    readonly property string face: hasFace ? `file://${facePath}` : ""

    FileView {
        path: root.facePath
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.hasFace = true
        onLoadFailed: root.hasFace = false
    }
    readonly property string uptime: SystemStats.uptime > 0 ? `ligado há ${Format.duration(SystemStats.uptime)}` : ""

    // Relógio
    readonly property string time: Qt.formatTime(clock.date, "HH:mm")
    readonly property string weekday: Format.capitalize(clock.date.toLocaleDateString(locale, "dddd"))
    readonly property string date: clock.date.toLocaleDateString(locale, "d 'de' MMMM")

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    // Calendário: mês mostrado (deslocamento em relação ao atual) e 42 células.
    property int monthOffset: 0
    readonly property var shownMonth: new Date(clock.date.getFullYear(), clock.date.getMonth() + monthOffset, 1)
    readonly property string monthTitle: Format.capitalize(shownMonth.toLocaleDateString(locale, "MMMM 'de' yyyy"))
    readonly property var weekdayInitials: [0, 1, 2, 3, 4, 5, 6].map(d => locale.dayName(d, Locale.NarrowFormat).toUpperCase())
    readonly property var calendarDays: {
        const first = shownMonth;
        const start = new Date(first.getFullYear(), first.getMonth(), 1 - first.getDay());
        const today = clock.date.toDateString();
        return Array.from({ length: 42 }, (_, i) => {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            return { day: d.getDate(), inMonth: d.getMonth() === first.getMonth(), today: d.toDateString() === today };
        });
    }

    function shiftMonth(step: int): void {
        monthOffset += step;
    }

    function resetMonth(): void {
        monthOffset = 0;
    }

    // Resumos
    readonly property real cpu: SystemStats.cpuUsage
    readonly property real memory: SystemStats.memTotal > 0 ? SystemStats.memUsed / SystemStats.memTotal : 0
    readonly property real disk: SystemStats.disks.length ? SystemStats.disks[0].used / SystemStats.disks[0].size : 0

    readonly property bool hasWeather: Weather.current !== null
    readonly property string weatherIcon: hasWeather ? Icons.forWeather(Weather.current.code, Weather.current.isDay) : Icons.weather
    readonly property string weatherTemp: hasWeather ? `${Math.round(Weather.current.temp)}°` : "—"
    readonly property string weatherText: hasWeather ? WeatherState.describe(Weather.current.code) : (Weather.location ? "Carregando…" : "Escolha a cidade na aba Clima")
    readonly property string weatherPlace: Weather.location?.name.split(",")[0] ?? ""

    readonly property bool hasMedia: Media.available
    readonly property string mediaTitle: Media.title || "Nada tocando"
    readonly property string mediaArtist: Media.artist
    readonly property string mediaArt: Media.artUrl
    readonly property bool mediaPlaying: Media.playing

    function togglePlaying(): void {
        Media.togglePlaying();
    }
}
