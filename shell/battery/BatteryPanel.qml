pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.components
import qs.services
import qs.theme

Panel {
    id: root

    property int lastPercent: Power.percent
    property int rollDirection: 1
    readonly property string note: {
        if (Power.degradation !== "")
            return `Performance limited · ${Power.degradation}`;
        const hold = Power.holds[0];
        if (hold)
            return [`Held at ${profileName(hold.profile)} by ${hold.applicationId}`, hold.reason].filter(Boolean).join(" · ");
        return "";
    }

    fromRight: true

    Connections {
        target: Power

        function onPercentChanged(): void {
            root.rollDirection = Power.percent >= root.lastPercent ? 1 : -1;
            root.lastPercent = Power.percent;
        }
    }

    Binding {
        target: Power
        property: "detailed"
        value: true
        when: root.open
    }

    function profileName(profile: int): string {
        if (profile === PowerProfile.PowerSaver)
            return "efficiency";
        if (profile === PowerProfile.Performance)
            return "performance";
        return "balanced";
    }

    function watts(value: real, signed: bool): string {
        const sign = !signed || value < 0.05 ? "" : Power.charging ? "+" : Power.discharging ? "−" : "";
        return `${sign}${Math.abs(value).toFixed(1)} W`;
    }

    function wattHours(value: real): string {
        return value > 0 ? `${value.toFixed(1)} Wh` : "—";
    }

    component SectionLabel: Label {
        pixelSize: 11
        color: Theme.fg2
    }

    Reveal {
        shown: root.open
        order: 0
        Layout.fillWidth: true
        implicitHeight: header.implicitHeight

        ColumnLayout {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                spacing: 16

                RollText {
                    Layout.preferredWidth: widest.advanceWidth
                    text: `${Power.percent}%`
                    display: true
                    pixelSize: 52
                    direction: root.rollDirection
                    color: Power.low ? Theme.red : Theme.fg

                    TextMetrics {
                        id: widest

                        font.family: Theme.displayFont
                        font.pixelSize: 52
                        font.weight: 800
                        text: "100%"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RollText {
                        Layout.fillWidth: true
                        text: Power.status
                        direction: root.rollDirection
                    }

                    Label {
                        Layout.fillWidth: true
                        pixelSize: 11
                        color: Theme.fg2
                        elide: Text.ElideRight
                        text: {
                            const parts = [];
                            if (Power.timeLeft !== "")
                                parts.push(Power.charging ? `${Power.timeLeft} to full` : `${Power.timeLeft} left`);
                            else if (Power.onAc)
                                parts.push("AC power");
                            if (Power.rate >= 0.05)
                                parts.push(root.watts(Power.rate, true));
                            return parts.join(" · ");
                        }
                    }
                }
            }

            LevelMeter {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                level: Power.level
                charging: Power.charging
            }
        }
    }

    Reveal {
        shown: root.open
        order: 1
        Layout.fillWidth: true
        implicitHeight: modes.implicitHeight

        ColumnLayout {
            id: modes

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 10

            DottedLine {
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                vertical: false
            }

            SectionLabel {
                Layout.leftMargin: 4
                text: "Power mode"
            }

            ProfileSwitch {
                Layout.fillWidth: true
            }

            Body {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                visible: root.note !== ""
                text: root.note
                font.pixelSize: 11
                color: Power.degradation !== "" ? Theme.red : Theme.fg2
            }
        }
    }

    Reveal {
        shown: root.open
        order: 2
        Layout.fillWidth: true
        implicitHeight: chart.implicitHeight

        ColumnLayout {
            id: chart

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 10

            DottedLine {
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                vertical: false
            }

            SectionLabel {
                Layout.leftMargin: 4
                text: "Charge · 24 h"
            }

            ChargeHistory {
                Layout.fillWidth: true
                Layout.leftMargin: 2
                Layout.rightMargin: 2
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4

                Label {
                    Layout.fillWidth: true
                    text: "−24 h"
                    pixelSize: 10
                    color: Theme.fg3
                }

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "−12 h"
                    pixelSize: 10
                    color: Theme.fg3
                }

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: "Now"
                    pixelSize: 10
                    color: Theme.fg3
                }
            }
        }
    }

    Reveal {
        shown: root.open
        order: 3
        Layout.fillWidth: true
        implicitHeight: details.implicitHeight

        ColumnLayout {
            id: details

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 8

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                rowSpacing: 8
                columnSpacing: 8

                Stat {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    heading: "Health"
                    value: Power.healthKnown ? `${Math.round(Power.health)}%` : "—"
                }

                Stat {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    heading: "Rate"
                    value: root.watts(Power.rate, true)
                }

                Stat {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    heading: "Voltage"
                    value: Power.voltage > 0 ? `${Power.voltage.toFixed(2)} V` : "—"
                }

                Stat {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    heading: "Energy"
                    value: root.wattHours(Power.energy)
                }

                Stat {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    heading: "Full"
                    value: root.wattHours(Power.energyFull)
                }

                Stat {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    heading: "Design"
                    value: root.wattHours(Power.energyDesign)
                }
            }

            Repeater {
                model: Power.batteries.length > 1 ? Power.batteries : []

                RowLayout {
                    id: batteryRow

                    required property UPowerDevice modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    spacing: 8

                    Body {
                        Layout.fillWidth: true
                        text: batteryRow.modelData.model || `Battery ${batteryRow.index + 1}`
                    }

                    Label {
                        pixelSize: 11
                        color: Theme.fg2
                        text: [`${Math.round(batteryRow.modelData.percentage * 100)}%`, batteryRow.modelData.healthSupported ? `health ${Math.round(batteryRow.modelData.healthPercentage)}%` : ""].filter(Boolean).join(" · ")
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                Layout.topMargin: 2

                Label {
                    Layout.fillWidth: true
                    pixelSize: 10
                    color: Theme.fg3
                    elide: Text.ElideRight
                    font.capitalization: Font.MixedCase
                    text: [Power.battery?.model ?? "", Power.battery?.nativePath ?? ""].filter(Boolean).join(" · ")
                }

                Label {
                    pixelSize: 10
                    color: Theme.fg3
                    text: Power.cycles > 0 ? `${Power.cycles} cycles` : Power.onAc ? "On AC" : "On battery"
                }
            }
        }
    }
}
