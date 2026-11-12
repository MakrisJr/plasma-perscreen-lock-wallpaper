/*
    Per-Screen Image wallpaper.
    Picks an image based on the connector name of the screen it is drawn on
    (Screen.name, e.g. "DP-3"), so the lock screen can show a different
    image on every monitor.

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.plasmoid

WallpaperItem {
    id: root

    readonly property string screenName: Screen.name

    readonly property string imageForScreen: {
        const entries = root.configuration.ScreenImages || [];
        for (let i = 0; i < entries.length; ++i) {
            const entry = String(entries[i]);
            const sep = entry.indexOf("=");
            if (sep > 0 && entry.substring(0, sep) === root.screenName) {
                return entry.substring(sep + 1);
            }
        }
        return root.configuration.FallbackImage || "";
    }

    Rectangle {
        anchors.fill: parent
        color: root.configuration.Color
    }

    Image {
        anchors.fill: parent
        source: root.imageForScreen
        fillMode: root.configuration.FillMode
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter
        asynchronous: true
        smooth: true
        mipmap: true
        sourceSize: Qt.size(root.width * Screen.devicePixelRatio,
                            root.height * Screen.devicePixelRatio)
    }
}
