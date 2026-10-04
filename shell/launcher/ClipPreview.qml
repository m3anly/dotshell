pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.services
import qs.theme
import "LauncherLogic.js" as Logic

Item {
    id: root

    property var entry: null
    property string fullText: ""
    property string imageFile: ""
    readonly property string type: entry?.type ?? ""
    readonly property var meta: {
        if (!entry)
            return [];
        const rows = [["Type", entry.pinned ? `${type} · pinned` : type]];
        if (entry.source)
            rows.push(["Source", entry.source]);
        if (entry.time > 0)
            rows.push(["Copied", Logic.ageText(Time.now - entry.time)]);
        if (type === "image")
            rows.push(["Image", entry.imageInfo]);
        else if (type === "file")
            rows.push(["Files", String(entry.files.length)]);
        else if (type !== "color") {
            const words = fullText.trim() === "" ? 0 : fullText.trim().split(/\s+/).length;
            rows.push(["Length", `${fullText.length} chars · ${words} words`]);
        }
        return rows;
    }

    onEntryChanged: load()

    function load(): void {
        const current = entry;
        fullText = current?.text ?? "";
        imageFile = current?.type === "image" ? current.file : "";
        if (!current || current.type === "image" || current.type === "file")
            return;
        Clipboard.fullText(current, text => {
            if (root.entry?.key === current.key)
                root.fullText = text;
        });
    }

    Label {
        anchors.centerIn: parent
        visible: root.entry === null
        text: "Nothing to preview"
        color: Theme.fg2
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        visible: root.entry !== null
        spacing: 18

        Item {
            id: stage

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Text {
                width: parent.width
                visible: root.type === "text"
                text: root.fullText.slice(0, 6000)
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                lineHeight: 1.6
                font.family: Theme.uiFont
                font.pixelSize: 15
                color: Theme.fg
            }

            Rectangle {
                width: parent.width
                height: Math.min(parent.height, code.implicitHeight + 32)
                visible: root.type === "code"
                radius: 12
                color: Qt.rgba(0, 0, 0, 0.3)
                border.width: 1
                border.color: Theme.line
                clip: true

                Text {
                    id: code

                    x: 16
                    y: 16
                    width: parent.width - 32
                    text: `<span style="color:${Theme.red}">$ </span><span style="white-space:pre-wrap">${Logic.escapeHtml(root.fullText.slice(0, 6000))}</span>`
                    textFormat: Text.RichText
                    wrapMode: Text.WrapAnywhere
                    lineHeight: 1.6
                    font.family: Theme.uiFont
                    font.pixelSize: 14
                    color: Theme.fg
                }
            }

            Column {
                width: parent.width
                visible: root.type === "link"
                spacing: 14

                Text {
                    width: parent.width
                    text: Logic.linkHost(root.fullText)
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    font.family: Theme.uiFont
                    font.pixelSize: 26
                    color: Theme.fg
                }

                Text {
                    width: parent.width
                    text: root.fullText.trim()
                    textFormat: Text.PlainText
                    wrapMode: Text.WrapAnywhere
                    lineHeight: 1.5
                    font.family: Theme.uiFont
                    font.pixelSize: 13
                    color: Theme.fg2
                }
            }

            Column {
                width: parent.width
                visible: root.type === "file"
                spacing: 14

                Repeater {
                    model: root.type === "file" ? root.entry.files.slice(0, 8) : []

                    Row {
                        id: fileRow

                        required property string modelData
                        readonly property int cut: modelData.lastIndexOf("/")

                        width: parent.width
                        spacing: 14

                        DotIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 14
                            name: "file"
                            color: Theme.fg2
                        }

                        Column {
                            width: parent.width - 28
                            spacing: 3

                            Text {
                                width: parent.width
                                text: fileRow.modelData.slice(fileRow.cut + 1)
                                textFormat: Text.PlainText
                                elide: Text.ElideMiddle
                                font.family: Theme.uiFont
                                font.pixelSize: 15
                                color: Theme.fg
                            }

                            Text {
                                width: parent.width
                                text: fileRow.cut > 0 ? fileRow.modelData.slice(0, fileRow.cut) : "/"
                                textFormat: Text.PlainText
                                elide: Text.ElideMiddle
                                font.family: Theme.uiFont
                                font.pixelSize: 12
                                color: Theme.fg2
                            }
                        }
                    }
                }

                Body {
                    visible: root.type === "file" && root.entry.files.length > 8
                    text: `+${(root.entry?.files.length ?? 0) - 8} more`
                    color: Theme.fg2
                }
            }

            Row {
                visible: root.type === "color"
                spacing: 24

                Rectangle {
                    width: 150
                    height: 150
                    radius: 75
                    color: root.type === "color" ? root.fullText.trim() : "transparent"
                    border.width: 1
                    border.color: Theme.line
                    antialiasing: true
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Repeater {
                        model: {
                            if (root.type !== "color")
                                return [];
                            const rgb = Logic.hexToRgb(root.fullText);
                            const hsl = Logic.rgbToHsl(rgb);
                            return [["HEX", root.fullText.trim().toUpperCase()], ["RGB", rgb.join(" ")], ["HSL", `${hsl[0]}° ${hsl[1]}% ${hsl[2]}%`]];
                        }

                        Row {
                            id: value

                            required property var modelData

                            Body {
                                width: 46
                                font.pixelSize: 14
                                text: value.modelData[0]
                                color: Theme.fg2
                            }

                            Body {
                                font.pixelSize: 14
                                text: value.modelData[1]
                            }
                        }
                    }
                }
            }

            ClippingRectangle {
                readonly property real ratio: image.implicitWidth > 0 ? image.implicitHeight / image.implicitWidth : 9 / 16

                width: parent.width
                height: Math.min(parent.height, width * ratio)
                visible: root.type === "image"
                radius: 12
                color: Theme.fill
                border.width: 1
                border.color: Theme.line

                Image {
                    id: image

                    anchors.fill: parent
                    source: root.imageFile !== "" ? `file://${root.imageFile}` : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                    sourceSize.width: 1200
                }
            }
        }

        DottedLine {
            Layout.fillWidth: true
            vertical: false
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 18
            rowSpacing: 8

            Repeater {
                model: root.meta.length * 2

                Body {
                    id: cell

                    required property int index
                    readonly property bool term: index % 2 === 0

                    Layout.fillWidth: !term
                    text: root.meta[Math.floor(index / 2)]?.[index % 2] ?? ""
                    font.pixelSize: 12
                    font.capitalization: term ? Font.AllUppercase : Font.MixedCase
                    font.letterSpacing: term ? 12 * 0.06 : 0
                    color: term ? Theme.fg2 : Theme.fg
                }
            }
        }
    }
}
