pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.components
import qs.services
import qs.theme

PopupWindow {
    id: menu

    property QsMenuHandle handle: null
    property var submenuEntry: null
    property Item submenuRow: null
    readonly property var entries: opener.children.values
    readonly property TrayMenu child: submenu.item as TrayMenu
    readonly property bool hovered: hover.hovered || (child?.hovered ?? false)

    signal chosen

    function label(text: string): string {
        return text.replace(/__|_/g, match => match === "__" ? "_" : "");
    }

    function openSubmenu(entry: var, row: Item): void {
        closeTimer.stop();
        submenuEntry = entry;
        submenuRow = row;
    }

    function closeSubmenu(): void {
        submenuEntry = null;
        submenuRow = null;
    }

    implicitWidth: Math.max(160, Math.min(360, rows.implicitWidth + 8))
    implicitHeight: rows.implicitHeight + 8
    color: "transparent"
    grabFocus: true
    BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null
    onVisibleChanged: {
        if (!visible)
            closeSubmenu();
        else
            keys.forceActiveFocus();
    }

    Region {
        id: blurRegion

        item: surface
        radius: surface.radius
    }

    QsMenuOpener {
        id: opener

        menu: menu.handle
    }

    Timer {
        id: closeTimer

        interval: 200
        onTriggered: {
            if (!(menu.child?.hovered ?? false))
                menu.closeSubmenu();
        }
    }

    Rectangle {
        id: surface

        anchors.fill: parent
        radius: 12
        color: Theme.glass(Theme.tintPanel)
        border.width: 1
        border.color: Theme.line
        antialiasing: true

        HoverHandler {
            id: hover
        }

        Item {
            id: keys

            focus: true
            Keys.onEscapePressed: menu.visible = false
        }

        ColumnLayout {
            id: rows

            x: 4
            y: 4
            width: parent.width - 8
            spacing: 0

            Repeater {
                model: opener.children

                Item {
                    id: row

                    required property QsMenuEntry modelData
                    required property int index
                    readonly property bool open: menu.submenuEntry === modelData
                    readonly property bool hasIndicator: modelData.buttonType !== QsMenuButtonType.None
                    readonly property string iconSource: Apps.resolveIcon(modelData.icon)

                    visible: !modelData.isSeparator || (index > 0 && index < menu.entries.length - 1 && !menu.entries[index - 1].isSeparator)
                    Layout.fillWidth: true
                    implicitWidth: modelData.isSeparator ? 0 : content.implicitWidth + 20
                    implicitHeight: modelData.isSeparator ? 9 : 30

                    Rectangle {
                        visible: row.modelData.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        x: 8
                        width: parent.width - 16
                        height: 1
                        color: Theme.line
                    }

                    Rectangle {
                        visible: !row.modelData.isSeparator
                        anchors.fill: parent
                        radius: 8
                        color: row.modelData.enabled && (rowMouse.containsMouse || row.open) ? Theme.hover : "transparent"
                        antialiasing: true
                    }

                    RowLayout {
                        id: content

                        visible: !row.modelData.isSeparator
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10
                        opacity: row.modelData.enabled ? 1 : 0.4

                        Item {
                            visible: row.hasIndicator || (iconProbe.probed && !iconProbe.blank && entryIcon.status !== Image.Error)
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16

                            Rectangle {
                                visible: row.hasIndicator
                                anchors.centerIn: parent
                                width: 12
                                height: 12
                                radius: row.modelData.buttonType === QsMenuButtonType.RadioButton ? 6 : 3
                                color: row.modelData.checkState === Qt.Checked ? Theme.fg : row.modelData.checkState === Qt.PartiallyChecked ? Theme.fg2 : "transparent"
                                border.width: 1
                                border.color: Theme.fg2
                                antialiasing: true
                            }

                            IconImage {
                                id: entryIcon

                                visible: !row.hasIndicator
                                anchors.fill: parent
                                source: row.hasIndicator ? "" : row.iconSource
                            }
                        }

                        Body {
                            Layout.fillWidth: true
                            text: menu.label(row.modelData.text)
                        }

                        DotIcon {
                            visible: row.modelData.hasChildren
                            Layout.preferredWidth: 10
                            Layout.preferredHeight: 10
                            size: 10
                            name: "chev"
                            rotation: -90
                            color: Theme.fg2
                        }
                    }

                    Canvas {
                        id: iconProbe

                        readonly property string source: row.hasIndicator ? "" : row.iconSource
                        property bool probed: false
                        property bool blank: false

                        width: 16
                        height: 16
                        opacity: 0
                        visible: source !== ""
                        onSourceChanged: {
                            probed = false;
                            if (source !== "")
                                loadImage(source);
                        }
                        Component.onCompleted: {
                            if (source !== "")
                                loadImage(source);
                        }
                        onImageLoaded: requestPaint()
                        onPaint: {
                            if (!isImageLoaded(source))
                                return;
                            const context = getContext("2d");
                            context.clearRect(0, 0, width, height);
                            context.drawImage(source, 0, 0, width, height);
                            const pixels = context.getImageData(0, 0, width, height).data;
                            let opaque = false;
                            for (let i = 3; i < pixels.length && !opaque; i += 4)
                                opaque = pixels[i] > 0;
                            blank = !opaque;
                            probed = true;
                        }
                    }

                    MouseArea {
                        id: rowMouse

                        anchors.fill: parent
                        enabled: !row.modelData.isSeparator && row.modelData.enabled
                        hoverEnabled: true
                        onContainsMouseChanged: {
                            if (!containsMouse)
                                return;
                            if (row.modelData.hasChildren)
                                menu.openSubmenu(row.modelData, row);
                            else if (menu.submenuEntry !== null)
                                closeTimer.restart();
                        }
                        onClicked: {
                            if (row.modelData.hasChildren) {
                                menu.openSubmenu(row.modelData, row);
                                return;
                            }
                            row.modelData.triggered();
                            menu.chosen();
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: submenu

        active: menu.visible && menu.submenuEntry !== null
        source: "TrayMenu.qml"
        onLoaded: {
            menu.child.handle = Qt.binding(() => menu.submenuEntry);
            menu.child.anchor.item = Qt.binding(() => menu.submenuRow);
            menu.child.anchor.rect.x = Qt.binding(() => (menu.submenuRow?.width ?? 0) + 6);
            menu.child.anchor.rect.y = -4;
            menu.child.anchor.rect.width = 1;
            menu.child.anchor.rect.height = 1;
            menu.child.anchor.edges = Edges.Top | Edges.Left;
            menu.child.anchor.gravity = Edges.Bottom | Edges.Right;
            menu.child.chosen.connect(menu.chosen);
            menu.child.visible = true;
        }

        Connections {
            target: menu.child

            function onVisibleChanged(): void {
                if (!menu.child.visible)
                    menu.closeSubmenu();
            }
        }
    }
}
