pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme

TabPage {
    id: root

    readonly property var days: Weather.daily
    readonly property real weekLow: days.length > 0 ? Math.min(...days.map(day => day.min)) : 0
    readonly property real weekHigh: days.length > 0 ? Math.max(...days.map(day => day.max)) : 1
    readonly property real currentTemperature: Store.weather?.temperature ?? 0
    readonly property int age: Math.max(0, Math.round((Weather.now - Weather.updated) / 60000))

    tab: "weather"
    implicitHeight: Weather.available ? layout.implicitHeight : empty.implicitHeight

    function localDate(time: real): date {
        return new Date(time + Weather.offset * 1000);
    }

    function clock(time: real): string {
        const local = localDate(time);
        return Time.clockText(local.getUTCHours(), local.getUTCMinutes());
    }

    component SmallButton: MorphButton {
        id: small

        property string text

        implicitWidth: smallLabel.implicitWidth + 24
        implicitHeight: 30
        restRadius: 15
        pressRadius: 8
        pressScale: 0.92
        hoverColor: Theme.hover

        Label {
            id: smallLabel

            anchors.centerIn: parent
            text: small.text
            pixelSize: 11
        }
    }

    ColumnLayout {
        id: empty

        anchors.left: parent.left
        anchors.right: parent.right
        visible: !Weather.available
        spacing: 14

        Item {
            Layout.preferredHeight: 18
        }

        DotIcon {
            Layout.alignment: Qt.AlignHCenter
            name: "cloud"
            size: 36
            color: Theme.fg3
        }

        Body {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Weather.query === "" ? "Set a location to see the weather" : Weather.loading ? "Loading the forecast" : "The forecast is unavailable"
            color: Theme.fg2
        }

        LoadingDots {
            Layout.alignment: Qt.AlignHCenter
            visible: Weather.loading
        }

        SmallButton {
            Layout.alignment: Qt.AlignHCenter
            visible: !Weather.loading
            text: Weather.query === "" ? "Open settings" : "Try again"
            onClicked: {
                if (Weather.query === "")
                    Ui.openSettings("weather");
                else
                    Weather.refresh();
            }
        }

        Item {
            Layout.preferredHeight: 18
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        visible: Weather.available
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            spacing: 18

            DotIcon {
                name: Weather.glyph
                size: 44
            }

            ColumnLayout {
                spacing: 0

                DisplayText {
                    text: Weather.temperature
                    font.pixelSize: 56
                    Layout.topMargin: -8
                    Layout.bottomMargin: -6
                }

                Label {
                    text: Weather.condition
                    pixelSize: 12
                    color: Theme.fg2
                }
            }

            Item {
                Layout.fillWidth: true
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                spacing: 6

                Label {
                    Layout.alignment: Qt.AlignRight
                    text: Weather.place || Weather.query
                    pixelSize: 12
                }

                Label {
                    Layout.alignment: Qt.AlignRight
                    visible: Weather.today !== null
                    text: Weather.today ? `H ${Weather.formatTemperature(Weather.today.max)} · L ${Weather.formatTemperature(Weather.today.min)}` : ""
                    pixelSize: 11
                    color: Theme.fg2
                }

                Row {
                    Layout.alignment: Qt.AlignRight
                    spacing: 8

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !Weather.loading
                        text: root.age < 1 ? "Updated now" : `Updated ${root.age} min ago`
                        pixelSize: 10
                        color: Theme.fg3
                    }

                    LoadingDots {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Weather.loading
                        dot: 3
                        color: Theme.fg2
                    }

                    MorphButton {
                        implicitWidth: 26
                        implicitHeight: 26
                        restRadius: 13
                        pressRadius: 6
                        pressScale: 0.88
                        restColor: "transparent"
                        hoverColor: Theme.hover
                        outline: "transparent"
                        enabled: !Weather.loading
                        opacity: enabled ? 1 : 0.4
                        onClicked: Weather.refresh()

                        DotIcon {
                            anchors.centerIn: parent
                            name: "reboot"
                            size: 11
                            color: Theme.fg2
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    {
                        heading: "Feels like",
                        value: Weather.feelsLike || "—"
                    },
                    {
                        heading: "Humidity",
                        value: `${Weather.humidity}%`
                    },
                    {
                        heading: "Wind",
                        value: Weather.wind || "—"
                    },
                    {
                        heading: "Sunrise",
                        value: Weather.today ? root.clock(Weather.today.sunrise) : "—"
                    },
                    {
                        heading: "Sunset",
                        value: Weather.today ? root.clock(Weather.today.sunset) : "—"
                    }
                ]

                Stat {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    heading: modelData.heading
                    value: modelData.value
                }
            }
        }

        Label {
            Layout.leftMargin: 4
            Layout.topMargin: 4
            text: "Next 24 h"
            pixelSize: 11
            color: Theme.fg2
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            TemperatureChart {
                id: chart

                Layout.fillWidth: true
                hours: Weather.hourly
            }

            Row {
                Layout.fillWidth: true

                Repeater {
                    model: Math.floor(Weather.hourly.length / 3)

                    Column {
                        id: slot

                        required property int index
                        readonly property var hour: Weather.hourly[index * 3 + 1] ?? Weather.hourly[index * 3]

                        width: chart.width / chart.columns * 3
                        spacing: 6

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: slot.hour ? Time.hourText(root.localDate(slot.hour.time).getUTCHours()) : ""
                            pixelSize: 10
                            color: Theme.fg3
                        }

                        DotIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: slot.hour ? Weather.glyphFor(slot.hour.code, slot.hour.isDay) : ""
                            size: 12
                            color: Theme.fg2
                        }

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: slot.hour ? Weather.formatTemperature(slot.hour.temperature) : ""
                            pixelSize: 11
                        }
                    }
                }
            }
        }

        DottedLine {
            Layout.fillWidth: true
            Layout.topMargin: 2
            vertical: false
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: root.days

                RowLayout {
                    id: dayRow

                    required property var modelData
                    required property int index
                    readonly property bool isToday: modelData.time === Weather.today?.time
                    readonly property int cells: 22
                    readonly property real span: Math.max(1, root.weekHigh - root.weekLow)
                    readonly property int from: Math.round((modelData.min - root.weekLow) / span * (cells - 1))
                    readonly property int to: Math.round((modelData.max - root.weekLow) / span * (cells - 1))
                    readonly property int now: isToday ? Math.round((Math.max(modelData.min, Math.min(modelData.max, root.currentTemperature)) - root.weekLow) / span * (cells - 1)) : -1

                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    implicitHeight: 28
                    spacing: 12

                    Label {
                        Layout.preferredWidth: 52
                        text: dayRow.isToday ? "Today" : Time.shortDayName(root.localDate(dayRow.modelData.time).getUTCDay())
                        pixelSize: 11
                        color: dayRow.isToday ? Theme.fg : Theme.fg2
                    }

                    DotIcon {
                        name: Weather.glyphFor(dayRow.modelData.code, true)
                        size: 12
                    }

                    Label {
                        Layout.preferredWidth: 40
                        text: dayRow.modelData.precipitation > 0 ? `${dayRow.modelData.precipitation}%` : ""
                        pixelSize: 10
                        color: Theme.fg3
                    }

                    Label {
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                        text: Weather.formatTemperature(dayRow.modelData.min)
                        pixelSize: 11
                        color: Theme.fg2
                    }

                    Item {
                        id: track

                        Layout.fillWidth: true
                        implicitHeight: 8

                        Repeater {
                            model: dayRow.cells

                            Rectangle {
                                required property int index
                                readonly property bool inRange: index >= dayRow.from && index <= dayRow.to

                                x: index * (track.width - 6) / (dayRow.cells - 1)
                                y: 1
                                width: 6
                                height: 6
                                radius: 3
                                antialiasing: true
                                color: index === dayRow.now ? Theme.red : inRange ? Theme.fg : Theme.off
                            }
                        }
                    }

                    Label {
                        Layout.preferredWidth: 40
                        text: Weather.formatTemperature(dayRow.modelData.max)
                        pixelSize: 11
                    }
                }
            }
        }
    }
}
