import QtQuick
import qs.components
import qs.services

Bay {
    id: bay

    property int previousIndex: Niri.layoutIndex

    visible: Niri.layoutNames.length > 1
    interactive: true
    onClicked: Niri.nextLayout()

    RollText {
        id: label

        elide: Text.ElideNone
        Component.onCompleted: text = Niri.layoutShort
    }

    Connections {
        target: Niri

        function onLayoutShortChanged(): void {
            label.direction = Niri.layoutIndex >= bay.previousIndex ? 1 : -1;
            bay.previousIndex = Niri.layoutIndex;
            label.text = Niri.layoutShort;
        }
    }
}
