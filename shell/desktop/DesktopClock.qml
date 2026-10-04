import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import qs.theme

PanelWindow {
    id: window

    readonly property real defaultRight: 72
    readonly property real defaultBottom: 128
    property real placedRight: -1
    property real placedBottom: -1
    readonly property real clockRight: placedRight >= 0 ? placedRight : Store.clock.right >= 0 ? Store.clock.right : defaultRight
    readonly property real clockBottom: placedBottom >= 0 ? placedBottom : Store.clock.bottom >= 0 ? Store.clock.bottom : defaultBottom
    readonly property real anchoredX: width - 380 - clockRight
    readonly property real anchoredY: height - 380 - clockBottom
    readonly property bool legacyPosition: Store.ready && width > 0 && height > 0 && Store.clock.right < 0 && Store.clock.x >= 0
    property real dragX: 0
    property real dragY: 0
    property bool dragging: false
    property point pressPoint
    property point pressPos

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "dotshell-desktop"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: FollowingRegion {
        target: glyph
        mover: wrap
    }
    BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null

    FollowingRegion {
        id: blurRegion

        target: glyph
        mover: wrap
    }

    component FollowingRegion: Region {
        required property Item target
        required property Item mover
        readonly property real trackedX: mover.x
        readonly property real trackedY: mover.y
        readonly property real trackedScale: target.scale

        item: target
        shape: RegionShape.Ellipse
        onTrackedXChanged: changed()
        onTrackedYChanged: changed()
        onTrackedScaleChanged: changed()
    }

    onLegacyPositionChanged: {
        if (legacyPosition)
            Qt.callLater(adoptLegacyPosition);
    }

    function adoptLegacyPosition(): void {
        if (!legacyPosition)
            return;
        const x = Store.clock.x;
        const y = Store.clock.y;
        place(width - 380 - x, height - 380 - y);
        Store.clock.x = -1;
        Store.clock.y = -1;
    }

    function place(fromRight: real, fromBottom: real): void {
        placedRight = fromRight;
        placedBottom = fromBottom;
        Store.clock.right = fromRight;
        Store.clock.bottom = fromBottom;
    }

    function clampX(x: real): real {
        return Math.round(Math.max(8, Math.min(window.width - 388, x)));
    }

    function clampY(y: real): real {
        const top = Theme.barAtBottom ? 8 : Theme.barHeight + 8;
        const bottom = window.height - 420 - (Theme.barAtBottom ? Theme.barHeight : 0);
        return Math.round(Math.max(top, Math.min(bottom, y)));
    }

    function settle(): void {
        if (!dragging)
            return;
        place(width - 380 - dragX, height - 380 - dragY);
        dragging = false;
    }

    function flipMode(): void {
        Store.clock.mode = Store.clock.mode === "time" ? "date" : "time";
    }

    Item {
        id: wrap

        x: window.clampX(window.dragging ? window.dragX : window.anchoredX)
        y: window.clampY(window.dragging ? window.dragY : window.anchoredY)
        width: 380
        height: caption.visible ? glyph.height + 18 + caption.height : glyph.height

        Rectangle {
            id: glyph

            width: 380
            height: 380
            radius: width / 2
            color: Theme.glass(Theme.tintBar)
            border.width: 1
            border.color: window.dragging ? Theme.fg3 : Theme.line
            scale: window.dragging ? 1.04 : mouse.pressed ? 0.97 : 1

            Behavior on scale {
                enabled: !Motion.reduced

                SpatialFast {
                    epsilon: 0.002
                }
            }
            Behavior on border.color {
                EffectsColor {}
            }

            GlyphMatrix {
                anchors.fill: parent
                anchors.margins: 30
                mode: Store.clock.mode
            }

            MouseArea {
                id: mouse

                anchors.fill: parent
                cursorShape: window.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                onPressed: event => {
                    window.pressPoint = mapToItem(window.contentItem, event.x, event.y);
                    window.pressPos = Qt.point(wrap.x, wrap.y);
                }
                onPositionChanged: event => {
                    const point = mapToItem(window.contentItem, event.x, event.y);
                    const dx = point.x - window.pressPoint.x;
                    const dy = point.y - window.pressPoint.y;
                    if (!window.dragging && Math.hypot(dx, dy) < 6)
                        return;
                    window.dragX = window.clampX(window.pressPos.x + dx);
                    window.dragY = window.clampY(window.pressPos.y + dy);
                    window.dragging = true;
                }
                onReleased: {
                    if (window.dragging)
                        window.settle();
                    else
                        window.flipMode();
                }
                onCanceled: window.settle()
            }
        }

        RollText {
            id: caption

            anchors.top: glyph.bottom
            anchors.topMargin: 18
            anchors.horizontalCenter: parent.horizontalCenter
            width: implicitWidth
            visible: Config.clock.caption
            color: Theme.fg2
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideNone
            text: Store.clock.mode === "time" ? "Time · tap for date" : "Date · tap for time"
        }
    }
}
