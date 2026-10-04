import QtQuick
import qs.theme

Canvas {
    id: root

    property var values: []
    property int columns: 30
    property int rows: 5
    readonly property real pitch: width / columns

    implicitHeight: rows * 9

    onValuesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const rowPitch = height / rows;
        const radius = Math.min(pitch, rowPitch) * 0.3;
        const skip = columns - values.length;
        for (let column = 0; column < columns; column++) {
            const value = column < skip ? -1 : values[column - skip];
            const lit = value < 0 ? 0 : Math.max(1, Math.round(Math.min(1, value) * rows));
            const cx = (column + 0.5) * pitch;
            for (let row = 0; row < rows; row++) {
                const fromBottom = rows - row;
                let color = Theme.off;
                if (fromBottom === lit)
                    color = column === columns - 1 ? Theme.red : Theme.fg;
                else if (fromBottom < lit)
                    color = Theme.fg3;
                ctx.fillStyle = Theme.css(color);
                ctx.beginPath();
                ctx.arc(cx, (row + 0.5) * rowPitch, radius, 0, Math.PI * 2);
                ctx.fill();
            }
        }
    }
}
