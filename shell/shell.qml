//@ pragma UseQApplication
//@ pragma NativeTextRendering

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.bar
import qs.desktop
import qs.cheatsheet
import qs.config
import qs.launcher
import qs.lock
import qs.notifications
import qs.osd
import qs.panels
import qs.polkit
import qs.services
import qs.settings
import qs.wallpaper

ShellRoot {
    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen

            required property ShellScreen modelData

            WallpaperWindow {
                screen: perScreen.modelData
            }

            Bar {
                screen: perScreen.modelData
            }

            LazyLoader {
                active: !GameMode.hideWidgets

                DesktopClock {
                    screen: perScreen.modelData
                }
            }

            LauncherHost {
                output: perScreen.modelData
            }

            CheatsheetHost {
                output: perScreen.modelData
            }

            PanelHost {
                output: perScreen.modelData
            }

            OsdHost {
                output: perScreen.modelData
            }

            PolkitHost {
                output: perScreen.modelData
            }

            NotificationPopups {
                output: perScreen.modelData
            }
        }
    }

    LockScreen {}

    LazyLoader {
        active: Ui.settingsOpen

        SettingsWindow {}
    }

    Ipc {}

    Component.onCompleted: Clipboard.refresh()
}
