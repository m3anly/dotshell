import QtQuick
import qs.components

Loader {
    id: slot

    required property ShellPlugin modelData
    required property int index
    property string screenName

    sourceComponent: modelData.bar
    onLoaded: {
        if ("screenName" in item)
            item.screenName = Qt.binding(() => slot.screenName);
    }
}
