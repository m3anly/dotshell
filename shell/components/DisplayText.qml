import QtQuick
import qs.theme

Text {
    font.family: Theme.displayFont
    font.weight: 800
    font.variableAxes: Theme.displayAxes
    font.features: ({
            "tnum": 1
        })
    color: Theme.fg
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText
}
