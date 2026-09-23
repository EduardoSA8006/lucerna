import QtQuick
import Quickshell
import qs.features.bar.ui
import qs.features.dashboard.ui
import qs.features.launcher.ui
import qs.features.lockscreen.ui
import qs.features.notifications.ui
import qs.features.osd.ui
import qs.features.powerMenu.ui
import qs.features.themeSwitcher.ui
import qs.features.wallpaper.ui

ShellRoot {
    Wallpaper {}
    Bar {}
    Dashboard {}
    Launcher {}
    NotificationPopups {}
    NotificationCenter {}
    Osd {}
    PowerMenu {}
    Lockscreen {}
    ThemeSwitcher {}
}
