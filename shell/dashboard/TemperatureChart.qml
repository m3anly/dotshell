import QtQuick
import qs.theme

Canvas {
    id: root

    property var hours: []
    readonly property int columns: Math.max(1, hours.length)
    readonly property int rows: 8
    readonly property real low: Math.min(...hours.map(hour => hour.temperature))
    readonly property real high: Math.max(...hours.map(hour => hour.temperature))

    implicitHeight: rows * 9

    onHoursChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function levelOf(value: real): int {
        if (high - low < 0.5)
            return Math.ceil(rows / 2);
        return 1 + Math.round((value - low) / (high - low) * (rows - 1));
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const pitch = width / columns;
        const rowPitch = height / rows;
        const radius = Math.min(pitch, rowPitch) * 0.3;
        for (let column = 0; column < columns; column++) {
            const level = hours.length > 0 ? levelOf(hours[column].temperature) : 0;
            const cx = (column + 0.5) * pitch;
            for (let row = 0; row < rows; row++) {
                const fromBottom = rows - row;
                let color = Theme.off;
                if (fromBottom === level)
                    color = column === 0 ? Theme.red : Theme.fg;
                else if (fromBottom < level)
                    color = Theme.fg3;
                ctx.fillStyle = Theme.css(color);
                ctx.beginPath();
                ctx.arc(cx, (row + 0.5) * rowPitch, radius, 0, Math.PI * 2);
                ctx.fill();
            }
        }
    }
}
