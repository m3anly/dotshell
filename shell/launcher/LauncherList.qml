pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.theme

ListView {
    id: list

    property var rows: []
    property bool stagger: false
    property string leavingKey: ""
    property bool populating: false
    property int shownRows: 0
    property var pointer: null
    readonly property real pointerSlop: 4
    property bool followTop: true
    property int lastIndex: 0
    property string selectedKey: ""
    readonly property alias selectionBox: highlight
    readonly property var rowMap: {
        const map = {};
        rows.forEach(row => map[row.key] = row);
        return map;
    }
    readonly property var selectables: rows.map((row, rowIndex) => Object.assign({}, row, {
            row: rowIndex
        })).filter(item => item.selectable)
    readonly property int selectedIndex: selectables.findIndex(item => item.key === selectedKey)
    readonly property var current: selectables[selectedIndex] ?? null

    signal activated(var item, bool shift)

    interactive: contentHeight > height
    boundsBehavior: Flickable.StopAtBounds
    model: ScriptModel {
        comparisonMode: ObjectComparison.Identity
        values: list.rows.map(row => row.key)
    }

    onRowsChanged: {
        if (rows.length > 0 && shownRows === 0) {
            populating = true;
            populateEnd.restart();
        }
        shownRows = rows.length;
    }
    onSelectablesChanged: resolve()

    function resolve(): void {
        if (selectables.length === 0) {
            selectedKey = "";
            return;
        }
        if (followTop) {
            select(0, false);
            return;
        }
        if (selectedIndex < 0)
            select(Math.min(lastIndex, selectables.length - 1), false);
    }

    function select(index: int, animate: bool): void {
        const item = selectables[index];
        if (!item)
            return;
        if (item.key !== selectedKey && animate)
            highlight.glide();
        selectedKey = item.key;
        lastIndex = index;
    }

    function reset(): void {
        followTop = true;
        pointer = null;
        lastIndex = 0;
        resolve();
        positionViewAtBeginning();
    }

    function navigate(index: int): void {
        followTop = false;
        select(index, true);
        Qt.callLater(revealCurrent);
    }

    function moveVertical(direction: int): void {
        if (selectedIndex < 0)
            return;
        navigate(Math.max(0, Math.min(selectables.length - 1, selectedIndex + direction)));
    }

    function hover(key: string, scenePoint: point): void {
        if (pointer === null) {
            pointer = scenePoint;
            return;
        }
        if (Math.hypot(scenePoint.x - pointer.x, scenePoint.y - pointer.y) < pointerSlop)
            return;
        pointer = scenePoint;
        const index = selectables.findIndex(item => item.key === key);
        if (index < 0 || index === selectedIndex)
            return;
        followTop = false;
        select(index, true);
    }

    function click(key: string, shift: bool): void {
        const index = selectables.findIndex(item => item.key === key);
        if (index >= 0 && index !== selectedIndex) {
            followTop = false;
            select(index, true);
        }
        activate(shift);
    }

    function activate(shift: bool): void {
        if (!current)
            return;
        if (!Motion.reduced)
            pulse.restart();
        activated(current, shift);
    }

    function afterPulse(action: var): void {
        deferred.action = action;
        deferred.interval = Motion.reduced ? 0 : 90;
        deferred.restart();
    }

    function revealCurrent(): void {
        if (!current || !interactive)
            return;
        const item = itemAtIndex(current.row);
        if (!item) {
            positionViewAtIndex(current.row, ListView.Contain);
            return;
        }
        const top = item.y - topMargin;
        const bottom = item.y + item.height + bottomMargin;
        let target = contentY;
        if (top < contentY)
            target = top;
        else if (bottom > contentY + height)
            target = bottom - height;
        target = Math.max(originY - topMargin, Math.min(target, originY + contentHeight + bottomMargin - height));
        if (Motion.reduced) {
            contentY = target;
            return;
        }
        scroll.to = target;
        scroll.restart();
    }

    Timer {
        id: populateEnd

        interval: 120
        onTriggered: list.populating = false
    }

    Timer {
        id: deferred

        property var action: null

        onTriggered: {
            const action = deferred.action;
            deferred.action = null;
            if (action)
                action();
        }
    }

    SpatialStandard {
        id: scroll

        target: list
        property: "contentY"
    }

    Rectangle {
        id: highlight

        property var goal: null
        property bool gliding: false

        function glide(): void {
            if (Motion.reduced || opacity === 0)
                return;
            gliding = true;
            glideEnd.restart();
        }

        parent: list.contentItem
        z: -1
        x: goal?.x ?? 0
        y: goal?.y ?? 0
        width: goal?.width ?? 0
        height: goal?.height ?? 0
        radius: goal?.radius ?? 12
        opacity: list.current !== null && goal !== null ? 1 : 0
        color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        border.color: Theme.fg3
        antialiasing: true

        Behavior on x {
            enabled: highlight.gliding

            SpatialFast {}
        }
        Behavior on y {
            enabled: highlight.gliding

            SpatialFast {}
        }
        Behavior on width {
            enabled: highlight.gliding

            SpatialStandard {}
        }
        Behavior on height {
            enabled: highlight.gliding

            SpatialStandard {}
        }
        Behavior on radius {
            enabled: !Motion.reduced

            SpatialStandard {}
        }
        Behavior on opacity {
            Effects {}
        }

        Timer {
            id: glideEnd

            interval: Motion.standardMs + 40
            onTriggered: highlight.gliding = false
        }

        SequentialAnimation {
            id: pulse

            NumberAnimation {
                target: highlight
                property: "scale"
                to: 0.97
                duration: 110
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.effectsCurve
            }
            NumberAnimation {
                target: highlight
                property: "scale"
                to: 1
                duration: 150
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.effectsCurve
            }
        }
    }

    delegate: Item {
        id: slot

        required property string modelData
        required property int index
        property var lastRow: null
        readonly property var liveRow: list.rowMap[modelData] ?? null
        readonly property var row: liveRow ?? lastRow
        readonly property bool selected: row !== null && list.selectedKey === row.key
        readonly property real visualY: y + flip.y
        property bool placed: false
        property real lastY: 0

        width: list.width
        implicitHeight: (loader.item as Item)?.implicitHeight ?? 0
        height: implicitHeight
        onLiveRowChanged: {
            if (liveRow)
                lastRow = liveRow;
        }
        onYChanged: {
            const delta = lastY - y;
            lastY = y;
            if (!placed || delta === 0 || Motion.reduced)
                return;
            flip.y += delta;
            glide.restart();
        }
        Component.onCompleted: {
            if (Motion.reduced || !(list.stagger || !list.populating))
                return;
            loader.opacity = 0;
            loader.scale = 0.96;
            enter.start();
        }
        ListView.onRemove: {
            if (Motion.reduced || row?.key !== list.leavingKey)
                return;
            ListView.delayRemove = true;
            leave.start();
        }

        Timer {
            running: true
            interval: 0
            onTriggered: {
                slot.lastY = slot.y;
                slot.placed = true;
            }
        }

        SpatialStandard {
            id: glide

            target: flip
            property: "y"
            to: 0
        }

        SequentialAnimation {
            id: enter

            PauseAnimation {
                duration: list.stagger ? Math.max(0, Math.min(slot.index, 9)) * 22 : 0
            }
            ParallelAnimation {
                Effects {
                    target: loader
                    property: "opacity"
                    to: 1
                }
                SpatialStandard {
                    target: loader
                    property: "scale"
                    to: 1
                    epsilon: 0.002
                }
            }
        }

        SequentialAnimation {
            id: leave

            ParallelAnimation {
                Exit {
                    target: loader
                    property: "opacity"
                    to: 0
                    duration: 160
                }
                Exit {
                    target: flip
                    property: "x"
                    to: -24
                    duration: 160
                }
                Exit {
                    target: loader
                    property: "scale"
                    to: 0.96
                    duration: 160
                }
            }
            PropertyAction {
                target: slot
                property: "ListView.delayRemove"
                value: false
            }
        }

        Loader {
            id: loader

            width: parent.width
            transform: Translate {
                id: flip
            }
            sourceComponent: {
                switch (slot.row?.kind) {
                case "header":
                    return headerRow;
                case "note":
                    return noteRow;
                case "app":
                    return appRow;
                case "calc":
                    return calcRow;
                case "clip":
                    return clipRow;
                case "clipItem":
                    return clipItemRow;
                default:
                    return null;
                }
            }
        }

        Component {
            id: headerRow

            SectionHeader {
                row: slot.row
                first: list.rows[0]?.key === slot.row?.key
            }
        }

        Component {
            id: noteRow

            NoteRow {
                row: slot.row
            }
        }

        Component {
            id: appRow

            AppRow {
                row: slot.row
                selected: slot.selected
                highlight: list.selectionBox
                originY: slot.visualY
                onPointed: scenePoint => list.hover(slot.row.key, scenePoint)
                onActivated: shift => list.click(slot.row.key, shift)
            }
        }

        Component {
            id: calcRow

            CalcRow {
                row: slot.row
                selected: slot.selected
                highlight: list.selectionBox
                originY: slot.visualY
                onPointed: scenePoint => list.hover(slot.row.key, scenePoint)
                onActivated: shift => list.click(slot.row.key, shift)
            }
        }

        Component {
            id: clipRow

            ClipRow {
                row: slot.row
                selected: slot.selected
                highlight: list.selectionBox
                originY: slot.visualY
                onPointed: scenePoint => list.hover(slot.row.key, scenePoint)
                onActivated: shift => list.click(slot.row.key, shift)
            }
        }

        Component {
            id: clipItemRow

            ClipRow {
                row: slot.row
                compact: true
                selected: slot.selected
                highlight: list.selectionBox
                originY: slot.visualY
                onPointed: scenePoint => list.hover(slot.row.key, scenePoint)
                onActivated: shift => list.click(slot.row.key, shift)
            }
        }
    }
}
