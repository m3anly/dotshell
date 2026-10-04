import QtQuick
import qs.theme

Text {
    property int pixelSize: Theme.labelSize
    property real tracking: Theme.labelTracking

    font.family: Theme.uiFont
    font.pixelSize: pixelSize
    font.capitalization: Font.AllUppercase
    font.letterSpacing: pixelSize * tracking
    color: Theme.fg
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText
    maximumLineCount: 1
}
