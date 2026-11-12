/*
    Settings page for the Per-Screen Image wallpaper.
    Lists every connected screen (plus any configured screen that is not
    currently connected) with an image picker for each.

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls

Kirigami.FormLayout {
    id: root
    twinFormLayouts: parentLayout

    property alias formLayout: root

    property var cfg_ScreenImages: []
    property string cfg_FallbackImage: ""
    property int cfg_FillMode: 2
    property alias cfg_Color: colorButton.color

    // ---- helpers -----------------------------------------------------------

    function entries() {
        const list = cfg_ScreenImages || [];
        const out = [];
        for (let i = 0; i < list.length; ++i) {
            out.push(String(list[i]));
        }
        return out;
    }

    function imageFor(name) {
        const list = entries();
        for (let i = 0; i < list.length; ++i) {
            const sep = list[i].indexOf("=");
            if (sep > 0 && list[i].substring(0, sep) === name) {
                return list[i].substring(sep + 1);
            }
        }
        return "";
    }

    function setImageFor(name, url) {
        const out = [];
        let found = false;
        const list = entries();
        for (let i = 0; i < list.length; ++i) {
            const sep = list[i].indexOf("=");
            if (sep > 0 && list[i].substring(0, sep) === name) {
                found = true;
                if (url) {
                    out.push(name + "=" + url);
                }
            } else {
                out.push(list[i]);
            }
        }
        if (!found && url) {
            out.push(name + "=" + url);
        }
        cfg_ScreenImages = out;
    }

    // Connected screens first, then configured-but-disconnected ones.
    readonly property var screenRows: {
        const rows = [];
        const seen = {};
        const screens = Qt.application.screens;
        for (let i = 0; i < screens.length; ++i) {
            const s = screens[i];
            const desc = [s.manufacturer, s.model].filter(x => x).join(" ");
            rows.push({
                name: s.name,
                detail: desc + (desc ? ", " : "") + s.width + "×" + s.height,
                connected: true
            });
            seen[s.name] = true;
        }
        const list = entries();
        for (let i = 0; i < list.length; ++i) {
            const sep = list[i].indexOf("=");
            const n = sep > 0 ? list[i].substring(0, sep) : "";
            if (n && !seen[n]) {
                rows.push({ name: n, detail: "not connected", connected: false });
                seen[n] = true;
            }
        }
        return rows;
    }

    // ---- file picker -------------------------------------------------------

    FileDialog {
        id: fileDialog
        property string target: ""      // screen name, or "" for the fallback
        title: target ? i18n("Choose image for %1", target) : i18n("Choose fallback image")
        nameFilters: [i18n("Images (*.png *.jpg *.jpeg *.webp *.bmp *.svg *.avif *.tif *.tiff)"),
                      i18n("All files (*)")]
        currentFolder: StandardPaths.writableLocation(StandardPaths.PicturesLocation)
        onAccepted: {
            const url = selectedFile.toString();
            if (target) {
                root.setImageFor(target, url);
            } else {
                root.cfg_FallbackImage = url;
            }
        }
    }

    // ---- per-screen rows ---------------------------------------------------

    Repeater {
        model: root.screenRows

        delegate: ColumnLayout {
            id: row
            required property var modelData
            readonly property string image: root.imageFor(modelData.name)

            Kirigami.FormData.label: modelData.name + ":"
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: row.modelData.detail
                opacity: 0.7
                font: Kirigami.Theme.smallFont
            }

            RowLayout {
                Rectangle {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 4.5
                    color: root.cfg_Color
                    border.color: Kirigami.Theme.disabledTextColor
                    border.width: 1

                    Image {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: row.image || root.cfg_FallbackImage
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: width * 2
                        sourceSize.height: height * 2
                        opacity: row.image ? 1 : 0.4
                    }
                }

                ColumnLayout {
                    QQC2.Label {
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 18
                        text: row.image ? decodeURIComponent(row.image.replace(/^file:\/\//, ""))
                                        : i18n("(uses fallback image)")
                        elide: Text.ElideMiddle
                    }
                    RowLayout {
                        QQC2.Button {
                            icon.name: "document-open"
                            text: i18n("Choose…")
                            onClicked: {
                                fileDialog.target = row.modelData.name;
                                fileDialog.open();
                            }
                        }
                        QQC2.Button {
                            icon.name: row.modelData.connected ? "edit-clear" : "edit-delete"
                            text: row.modelData.connected ? i18n("Clear") : i18n("Remove")
                            enabled: row.image !== ""
                            onClicked: root.setImageFor(row.modelData.name, "")
                        }
                    }
                }
            }
        }
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
    }

    // ---- fallback + appearance --------------------------------------------

    RowLayout {
        Kirigami.FormData.label: i18n("Fallback image:")
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 18
            text: root.cfg_FallbackImage
                  ? decodeURIComponent(root.cfg_FallbackImage.replace(/^file:\/\//, ""))
                  : i18n("(none, plain colour)")
            elide: Text.ElideMiddle
        }
        QQC2.Button {
            icon.name: "document-open"
            text: i18n("Choose…")
            onClicked: {
                fileDialog.target = "";
                fileDialog.open();
            }
        }
        QQC2.Button {
            icon.name: "edit-clear"
            enabled: root.cfg_FallbackImage !== ""
            onClicked: root.cfg_FallbackImage = ""
            QQC2.ToolTip.text: i18n("Clear")
            QQC2.ToolTip.visible: hovered
        }
    }

    QQC2.ComboBox {
        id: fillCombo
        Kirigami.FormData.label: i18n("Positioning:")
        textRole: "text"
        valueRole: "value"
        model: [
            { text: i18n("Scaled and Cropped"), value: Image.PreserveAspectCrop },
            { text: i18n("Scaled, Keep Proportions"), value: Image.PreserveAspectFit },
            { text: i18n("Scaled"), value: Image.Stretch },
            { text: i18n("Centered"), value: Image.Pad },
            { text: i18n("Tiled"), value: Image.Tile }
        ]
        Component.onCompleted: currentIndex = Math.max(0, indexOfValue(root.cfg_FillMode))
        onActivated: root.cfg_FillMode = currentValue
    }

    KQuickControls.ColorButton {
        id: colorButton
        Kirigami.FormData.label: i18n("Background colour:")
        dialogTitle: i18n("Select Background Colour")
    }
}
