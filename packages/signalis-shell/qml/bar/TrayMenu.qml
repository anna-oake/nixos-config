import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components
import qs.config

// A tray item's menu, dropped from its icon. Submenus open in place, with a
// row at the top to go back up.
Dropdown {
    id: root

    centered: true

    property SystemTrayItem item: null
    // Submenus entered so far; the last one is on screen.
    property var path: []

    readonly property var current: path.length > 0 ? path[path.length - 1] : item?.menu ?? null

    function show(trayItem, icon) {
        if (open && item === trayItem) {
            open = false;
            return;
        }
        open = false;
        item = trayItem;
        path = [];
        anchorItem = icon;
        open = true;
    }

    function activate(entry) {
        if (entry.hasChildren) {
            path = path.concat([entry]);
        } else {
            entry.triggered();
            open = false;
        }
    }

    onOpenChanged: if (!open) path = []

    // dbusmenu labels mark mnemonics with "_"; a doubled one is a literal.
    function label(text) {
        return text.replace(/_(.)/g, "$1");
    }

    QsMenuOpener {
        id: opener
        menu: root.current
    }

    Frame {
        id: frame
        label: root.item ? (root.item.tooltipTitle || root.item.title || root.item.id) : ""
        fill: Theme.raised
        borderColor: Theme.red

        // Measures the title tab, which sits 12px in.
        Txt {
            id: title
            visible: false
            text: frame.label
            caps: true
        }

        Column {
            id: rows
            // As wide as the widest row needs, and never narrower than the title.
            width: Math.max(140, title.implicitWidth + 40, ...Array.from(children).map(c => c.need ?? 0))
            spacing: 2

            Rectangle {
                readonly property real need: visible ? backText.implicitWidth + 12 : 0

                visible: root.path.length > 0
                width: parent.width
                height: 24
                color: back.containsMouse ? Theme.hover : "transparent"

                Txt {
                    id: backText
                    x: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: "< " + root.label(root.path[root.path.length - 1]?.text ?? "")
                    color: Theme.muted
                }

                MouseArea {
                    id: back
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.path = root.path.slice(0, -1)
                }
            }

            Repeater {
                model: opener.children

                Item {
                    id: entry

                    required property QsMenuEntry modelData
                    readonly property bool check: modelData.buttonType !== QsMenuButtonType.None
                    readonly property real need: modelData.isSeparator ? 0 : name.anchors.leftMargin + name.implicitWidth + 8 + more.implicitWidth + 6

                    width: parent.width
                    height: modelData.isSeparator ? 7 : 24

                    Rectangle {
                        visible: entry.modelData.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 1
                        color: Theme.alpha(Theme.line, 0.6)
                    }

                    Rectangle {
                        visible: !entry.modelData.isSeparator
                        anchors.fill: parent
                        color: row.containsMouse && entry.modelData.enabled ? Theme.hover : "transparent"

                        // Checkbox or radio: filled when on, hollow when off.
                        Rectangle {
                            id: mark
                            x: 6
                            anchors.verticalCenter: parent.verticalCenter
                            visible: entry.check
                            width: 8
                            height: 8
                            color: entry.modelData.checkState === Qt.Checked ? Theme.red : "transparent"
                            border.width: 1
                            border.color: Theme.red
                        }

                        IconImage {
                            id: icon
                            x: entry.check ? 22 : 6
                            anchors.verticalCenter: parent.verticalCenter
                            visible: entry.modelData.icon !== ""
                            implicitSize: 14
                            source: entry.modelData.icon
                            asynchronous: true
                        }

                        Txt {
                            id: name
                            anchors.left: parent.left
                            anchors.leftMargin: 6 + (entry.check ? 16 : 0) + (icon.visible ? 22 : 0)
                            anchors.right: more.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: root.label(entry.modelData.text)
                            color: entry.modelData.enabled ? Theme.ink : Theme.dim
                        }

                        Txt {
                            id: more
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: entry.modelData.hasChildren ? ">" : ""
                            color: Theme.muted
                        }

                        MouseArea {
                            id: row
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: entry.modelData.enabled
                            onClicked: root.activate(entry.modelData)
                        }
                    }
                }
            }
        }
    }
}
