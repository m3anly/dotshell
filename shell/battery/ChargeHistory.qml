import QtQuick
import qs.components
import qs.services

DotChart {
    id: root

    property var points: Power.history
    property real level: Power.level
    property real span: 24 * 3600 * 1000

    columns: 48
    rows: 8

    onPointsChanged: rebuild()
    onLevelChanged: rebuild()
    Component.onCompleted: rebuild()

    function rebuild(): void {
        const now = Date.now();
        const start = now - span;
        const list = [];
        let cursor = 0;
        let known = null;
        for (let column = 0; column < columns; column++) {
            const end = start + (column + 1) * span / columns;
            while (cursor < points.length && points[cursor].time <= end) {
                known = points[cursor];
                cursor++;
            }
            list.push(known ? known.value / 100 : -1);
        }
        list[columns - 1] = level;
        values = list;
    }
}
