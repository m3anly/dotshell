pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var locale: Qt.locale()
    readonly property bool hour12: /[aA]/.test(locale.timeFormat(Locale.ShortFormat).replace(/'[^']*'/g, ""))

    readonly property date date: clock.date
    readonly property int now: Math.floor(date.getTime() / 1000)
    readonly property string hhmm: hourText(clock.hours) + pad(clock.minutes)
    readonly property string period: periodOf(clock.hours)
    readonly property string dayLabel: `${shortDayName(date.getDay()).toUpperCase()} ${pad(date.getDate())} ${shortMonthName(date.getMonth()).toUpperCase()}`

    function pad(n: int): string {
        return String(n).padStart(2, "0");
    }

    function hourText(hours: int): string {
        return pad(hour12 ? (hours + 11) % 12 + 1 : hours);
    }

    function periodOf(hours: int): string {
        if (!hour12)
            return "";
        return (hours < 12 ? locale.amText : locale.pmText).toUpperCase();
    }

    function clockText(hours: int, minutes: int): string {
        const text = `${hourText(hours)}:${pad(minutes)}`;
        return hour12 ? `${text} ${periodOf(hours)}` : text;
    }

    function trimmed(name: string): string {
        return name.replace(/\.$/, "");
    }

    function capitalized(name: string): string {
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    function dayName(day: int): string {
        return capitalized(locale.dayName(day, Locale.LongFormat));
    }

    function shortDayName(day: int): string {
        return capitalized(trimmed(locale.dayName(day, Locale.ShortFormat)));
    }

    function dayInitials(day: int): string {
        return shortDayName(day).slice(0, 2);
    }

    function monthName(month: int): string {
        return capitalized(locale.monthName(month, Locale.LongFormat));
    }

    function shortMonthName(month: int): string {
        return capitalized(trimmed(locale.monthName(month, Locale.ShortFormat)));
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }
}
