import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services
import qs.theme

Item {
    id: root

    required property SystemTrayItem modelData
    readonly property string glyph: Config.trayGlyphs[modelData.id] ?? ""
    readonly property bool hovered: mouse.containsMouse
    readonly property string label: modelData.tooltipTitle || modelData.title || modelData.id
    readonly property string iconSource: Apps.resolveIcon(String(modelData.icon ?? ""))
    readonly property bool showsMonogram: glyph === "" && (iconSource === "" || appIcon.status === Image.Error)

    implicitWidth: Theme.iconSize
    implicitHeight: Theme.iconSize

    Item {
        id: face

        width: parent.width
        height: parent.height
        y: root.hovered && !mouse.pressed ? -1.5 : 0
        scale: mouse.pressed ? 0.85 : root.hovered ? 1.15 : 1

        Behavior on y {
            enabled: !Motion.reduced

            SpatialFast {}
        }
        Behavior on scale {
            enabled: !Motion.reduced

            SpatialFast {
                epsilon: 0.002
            }
        }

        DotIcon {
            visible: root.glyph !== ""
            anchors.fill: parent
            name: root.glyph
            color: root.hovered ? Theme.fg : Theme.fg2

            Behavior on color {
                EffectsColor {}
            }
        }

        IconImage {
            id: appIcon

            visible: false
            anchors.fill: parent
            source: root.glyph === "" ? root.iconSource : ""
            asynchronous: true
        }

        Rectangle {
            visible: root.showsMonogram
            anchors.fill: parent
            radius: 4
            color: root.hovered ? Theme.fg : Theme.fg2
            antialiasing: true

            Behavior on color {
                EffectsColor {}
            }

            Body {
                id: monogram

                readonly property rect ink: inkMetrics.tightBoundingRect

                x: Math.round((parent.width - ink.width) / 2 - ink.x)
                y: Math.round((parent.height - ink.height) / 2 - ink.y - baselineOffset)
                text: Apps.monogram(root.modelData.title || root.modelData.id)
                font.pixelSize: 11
                color: Theme.glassBase
            }

            TextMetrics {
                id: inkMetrics

                font: monogram.font
                text: monogram.text
            }
        }

        MultiEffect {
            visible: root.glyph === "" && !root.showsMonogram
            anchors.fill: parent
            source: appIcon
            saturation: -1
            opacity: root.hovered ? 1 : 0.7

            Behavior on opacity {
                Effects {}
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            const item = root.modelData;
            if (event.button === Qt.MiddleButton)
                item.secondaryActivate();
            else if (event.button === Qt.RightButton || item.onlyMenu)
                root.showMenu();
            else
                item.activate();
        }
    }

    function showMenu(): void {
        if (modelData.hasMenu)
            Ui.trayMenu = Ui.trayMenu === menu ? null : menu;
    }

    Connections {
        target: Ui

        function onTrayMenuChanged(): void {
            if (Ui.trayMenu !== menu)
                menu.visible = false;
            else
                Qt.callLater(() => menu.visible = Ui.trayMenu === menu);
        }
    }

    Tooltip {
        target: root
        text: root.label
        shown: root.hovered && !mouse.pressed && !menu.visible
    }

    TrayMenu {
        id: menu

        handle: menu.visible ? root.modelData.menu : null
        anchor.item: root
        anchor.rect.x: 0
        anchor.rect.y: Theme.barAtBottom ? -16 : root.height + 16
        anchor.rect.width: root.width
        anchor.rect.height: 1
        anchor.edges: Theme.barAtBottom ? Edges.Top : Edges.Bottom
        anchor.gravity: Theme.barAtBottom ? Edges.Top : Edges.Bottom
        onChosen: Ui.trayMenu = null
        onVisibleChanged: {
            if (!visible && Ui.trayMenu === menu)
                Ui.trayMenu = null;
        }
    }
}
