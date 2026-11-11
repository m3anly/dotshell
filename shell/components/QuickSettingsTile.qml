import QtQuick

QtObject {
    property string glyph
    property bool on: false
    property bool shown: true
    property string title
    property string subtitle
    property Component content: null

    signal toggled
}
