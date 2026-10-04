pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import qs.theme

Item {
    id: root

    readonly property int weekStart: Config.calendar.weekStart === "sunday" ? 0 : 1
    readonly property date today: Time.date
    property int offset: 0
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    readonly property int year: shown.getFullYear()
    readonly property int month: shown.getMonth()
    readonly property bool atToday: offset === 0
    readonly property real cell: width / 7
    readonly property var days: {
        const first = new Date(year, month, 1);
        const lead = (first.getDay() - weekStart + 7) % 7;
        const result = [];
        for (let i = 0; i < 42; i++) {
            const day = new Date(year, month, 1 - lead + i);
            result.push({
                day: day.getDate(),
                inMonth: day.getMonth() === month,
                weekend: day.getDay() === 0 || day.getDay() === 6,
                today: day.getFullYear() === today.getFullYear() && day.getMonth() === today.getMonth() && day.getDate() === today.getDate()
            });
        }
        return result;
    }

    implicitHeight: layout.implicitHeight

    function shift(step: int): void {
        title.direction = Math.sign(step);
        grid.enterFrom = Math.sign(step);
        offset += step;
        grid.slide();
    }

    function reset(): void {
        if (offset !== 0)
            shift(-offset);
    }

    function jumpToToday(): void {
        offset = 0;
    }

    component NavButton: MorphButton {
        id: nav

        property int step: 1

        implicitWidth: 30
        implicitHeight: 30
        restRadius: 15
        pressRadius: 8
        pressScale: 0.88
        restColor: "transparent"
        hoverColor: Theme.hover
        outline: "transparent"
        onClicked: root.shift(step)

        DotIcon {
            anchors.centerIn: parent
            size: 10
            name: "chev"
            rotation: nav.step > 0 ? -90 : 90
            color: Theme.fg2
        }
    }

    WheelHandler {
        property real accumulated: 0

        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            accumulated += event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
            if (Math.abs(accumulated) < 120)
                return;
            root.shift(accumulated > 0 ? -1 : 1);
            accumulated = 0;
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            spacing: 4

            RollText {
                id: title

                Layout.fillWidth: true
                text: `${Time.monthName(root.month)} ${root.year}`
            }

            MorphButton {
                visible: !root.atToday
                implicitWidth: todayLabel.implicitWidth + 24
                implicitHeight: 30
                restRadius: 15
                pressRadius: 8
                pressScale: 0.92
                hoverColor: Theme.hover
                onClicked: root.reset()

                Label {
                    id: todayLabel

                    anchors.centerIn: parent
                    text: "Today"
                    pixelSize: 11
                }
            }

            NavButton {
                step: -1
            }

            NavButton {
                step: 1
            }
        }

        Row {
            Layout.fillWidth: true

            Repeater {
                model: 7

                Label {
                    required property int index
                    readonly property int weekday: (index + root.weekStart) % 7

                    width: root.cell
                    horizontalAlignment: Text.AlignHCenter
                    text: Time.dayInitials(weekday)
                    pixelSize: 11
                    color: weekday === 0 || weekday === 6 ? Theme.fg3 : Theme.fg2
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.cell * 6 * 0.8
            clip: true

            Grid {
                id: grid

                property int enterFrom: 1

                function slide(): void {
                    if (Motion.reduced)
                        return;
                    enter.restart();
                }

                columns: 7
                transform: Translate {
                    id: gridShift
                }

                ParallelAnimation {
                    id: enter

                    SpatialStandard {
                        target: gridShift
                        property: "x"
                        from: grid.enterFrom * 28
                        to: 0
                    }
                    Effects {
                        target: grid
                        property: "opacity"
                        from: 0
                        to: 1
                    }
                }

                Repeater {
                    model: root.days

                    Item {
                        id: day

                        required property var modelData

                        width: root.cell
                        height: root.cell * 0.8

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) - 4
                            height: width
                            radius: width / 2
                            color: day.modelData.today ? Theme.red : "transparent"
                            antialiasing: true
                        }

                        Body {
                            anchors.centerIn: parent
                            text: day.modelData.day
                            font.pixelSize: 13
                            color: {
                                if (day.modelData.today)
                                    return Theme.fg;
                                if (!day.modelData.inMonth)
                                    return Theme.fg3;
                                return day.modelData.weekend ? Theme.fg2 : Theme.fg;
                            }
                        }
                    }
                }
            }
        }
    }
}
