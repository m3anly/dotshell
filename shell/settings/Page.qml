import QtQuick
import QtQuick.Layouts

ColumnLayout {
    property bool shown: false

    spacing: 0
    Component.onCompleted: shown = true
}
