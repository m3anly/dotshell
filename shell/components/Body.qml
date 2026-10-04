import QtQuick
import qs.theme

Text {
    font.family: Theme.uiFont
    font.pixelSize: 13
    color: Theme.fg
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText
    elide: Text.ElideRight
    maximumLineCount: 1
}
