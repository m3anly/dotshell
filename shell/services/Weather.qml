pragma Singleton

import QtQuick
import Quickshell
import qs.config

Singleton {
    id: root

    readonly property int refreshMs: Math.max(5, Config.weather.refreshMinutes) * 60 * 1000
    readonly property int retryMs: Math.min(5 * 60 * 1000, refreshMs)
    readonly property real staleMs: Math.max(1, Config.weather.hideAfterHours) * 60 * 60 * 1000
    readonly property var windUnits: ({
            kmh: {
                label: "km/h",
                perKmh: 1
            },
            mph: {
                label: "mph",
                perKmh: 0.621371
            },
            ms: {
                label: "m/s",
                perKmh: 1 / 3.6
            },
            kn: {
                label: "kn",
                perKmh: 0.539957
            }
        })
    readonly property string windUnit: Config.weather.windUnit in windUnits ? Config.weather.windUnit : units === "fahrenheit" ? "mph" : "kmh"
    readonly property string query: Config.weather.enabled ? Config.weather.location.trim() : ""
    readonly property string units: Config.weather.units === "fahrenheit" ? "fahrenheit" : "celsius"
    readonly property var cache: Store.weather ?? ({})
    readonly property bool matchesSettings: cache.query === query && cache.units === units
    property real now: Date.now()
    readonly property bool available: query !== "" && matchesSettings && typeof cache.code === "number" && now - (cache.time ?? 0) < staleMs
    readonly property string temperature: available ? formatTemperature(cache.temperature) : ""
    readonly property string condition: available ? describe(cache.code) : ""
    readonly property string glyph: available ? glyphFor(cache.code, cache.isDay) : "cloud"
    readonly property string place: available ? cache.place : ""
    readonly property string feelsLike: available && typeof cache.feelsLike === "number" ? formatTemperature(cache.feelsLike) : ""
    readonly property int humidity: available ? Math.round(cache.humidity ?? 0) : 0
    readonly property string wind: available && typeof cache.wind === "number" ? formatWind(cache.wind, cache.windUnit ?? (cache.units === "fahrenheit" ? "mph" : "kmh")) : ""
    readonly property int offset: available ? cache.offset ?? 0 : 0
    readonly property var hourly: available ? (cache.hourly ?? []).filter(hour => hour.time > now - 3600 * 1000).slice(0, 24) : []
    readonly property var daily: available ? cache.daily ?? [] : []
    readonly property var today: daily.find(day => day.time + 86400 * 1000 > now) ?? null
    readonly property real updated: available ? cache.time : 0
    property bool loading: false
    property int generation: 0

    function formatTemperature(value: real): string {
        const rounded = Math.round(value);
        if (rounded === 0)
            return "0°";
        return `${rounded > 0 ? "+" : "−"}${Math.abs(rounded)}°`;
    }

    function formatWind(value: real, from: string): string {
        const target = windUnits[windUnit];
        const kmh = value / (windUnits[from]?.perKmh ?? 1);
        return `${Math.round(kmh * target.perKmh)} ${target.label}`;
    }

    function describe(code: int): string {
        if (code === 0)
            return "Clear";
        if (code === 1)
            return "Mostly clear";
        if (code === 2)
            return "Partly cloudy";
        if (code === 3)
            return "Cloudy";
        if (code === 45 || code === 48)
            return "Fog";
        if (code >= 51 && code <= 57)
            return "Drizzle";
        if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82))
            return "Rain";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "Snow";
        if (code >= 95)
            return "Storm";
        return "";
    }

    function glyphFor(code: int, isDay: bool): string {
        if (code <= 1)
            return isDay ? "sun" : "moon";
        if (code === 45 || code === 48)
            return "fog";
        if (code >= 51 && code <= 67 || code >= 80 && code <= 82)
            return "rain";
        if (code >= 71 && code <= 77 || code === 85 || code === 86)
            return "snow";
        if (code >= 95)
            return "storm";
        return "cloud";
    }

    function request(url: string, done: var, failed: var): void {
        const xhr = new XMLHttpRequest();
        const guard = guardTimer.createObject(root);
        let settled = false;
        const settle = () => {
            if (settled)
                return false;
            settled = true;
            guard.destroy();
            return true;
        };
        guard.triggered.connect(() => {
            if (!settle())
                return;
            xhr.abort();
            failed();
        });
        guard.start();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || !settle())
                return;
            let body = null;
            try {
                body = JSON.parse(xhr.responseText);
            } catch (e) {}
            if (xhr.status === 200 && body)
                done(body);
            else
                failed();
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function resolve(text: string, done: var, failed: var): void {
        const coordinates = /^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$/.exec(text);
        if (coordinates) {
            done(Number(coordinates[1]), Number(coordinates[2]), "");
            return;
        }
        const city = text.split(",")[0].trim();
        const country = text.includes(",") ? text.slice(text.indexOf(",") + 1).trim().toLowerCase() : "";
        request(`https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(city)}&count=10&format=json`, body => {
            const results = body.results ?? [];
            const match = results.find(result => country === "" || [result.country, result.country_code, result.admin1].some(field => String(field ?? "").toLowerCase() === country)) ?? null;
            if (match)
                done(match.latitude, match.longitude, match.name);
            else
                failed();
        }, failed);
    }

    function refresh(): void {
        if (query === "" || loading)
            return;
        const asked = query;
        const askedUnits = units;
        const ticket = ++generation;
        loading = true;
        const fail = () => {
            if (ticket !== generation)
                return;
            loading = false;
            schedule.interval = retryMs;
            schedule.restart();
        };
        resolve(asked, (latitude, longitude, name) => {
            const fields = ["current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day", "hourly=temperature_2m,weather_code,is_day,precipitation_probability", "daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max"].join("&");
            request(`https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&${fields}&forecast_days=7&temperature_unit=${askedUnits}&wind_speed_unit=kmh&timeformat=unixtime&timezone=auto`, body => {
                if (ticket !== generation)
                    return;
                const current = body.current;
                if (!current) {
                    fail();
                    return;
                }
                const hours = body.hourly ?? {};
                const days = body.daily ?? {};
                Store.weather = {
                    temperature: current.temperature_2m,
                    feelsLike: current.apparent_temperature,
                    humidity: current.relative_humidity_2m,
                    wind: current.wind_speed_10m,
                    windUnit: "kmh",
                    code: current.weather_code,
                    isDay: current.is_day === 1,
                    offset: body.utc_offset_seconds ?? 0,
                    hourly: (hours.time ?? []).map((time, i) => ({
                                time: time * 1000,
                                temperature: hours.temperature_2m[i],
                                code: hours.weather_code[i],
                                isDay: hours.is_day[i] === 1,
                                precipitation: hours.precipitation_probability?.[i] ?? 0
                            })).filter(hour => hour.time > Date.now() - 3600 * 1000).slice(0, 48),
                    daily: (days.time ?? []).map((time, i) => ({
                                time: time * 1000,
                                code: days.weather_code[i],
                                max: days.temperature_2m_max[i],
                                min: days.temperature_2m_min[i],
                                sunrise: (days.sunrise?.[i] ?? 0) * 1000,
                                sunset: (days.sunset?.[i] ?? 0) * 1000,
                                precipitation: days.precipitation_probability_max?.[i] ?? 0
                            })),
                    place: name,
                    units: askedUnits,
                    query: asked,
                    time: Date.now()
                };
                now = Date.now();
                loading = false;
                schedule.interval = refreshMs;
                schedule.restart();
            }, fail);
        }, fail);
    }

    function start(): void {
        generation++;
        loading = false;
        schedule.stop();
        if (query === "" || !Store.ready)
            return;
        const stored = Store.weather ?? {};
        const age = Date.now() - (stored.time ?? 0);
        if (stored.query === query && stored.units === units && age < refreshMs && Array.isArray(stored.daily)) {
            schedule.interval = refreshMs - age;
            schedule.restart();
            return;
        }
        refresh();
    }

    onQueryChanged: start()
    onUnitsChanged: start()
    onRefreshMsChanged: start()
    Component.onCompleted: start()

    Connections {
        target: Store

        function onReadyChanged(): void {
            root.start();
        }
    }

    Timer {
        id: schedule

        onTriggered: root.refresh()
    }

    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }

    Component {
        id: guardTimer

        Timer {
            interval: 15000
        }
    }
}
