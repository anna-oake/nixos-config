import QtQuick
import Quickshell
import Quickshell.Wayland

// Panel dropped from a bar item. While it is open a transparent shield covers
// the screen, so a tap or click anywhere else only closes the panel and never
// lands in the window underneath.
Scope {
    id: root

    required property Item anchorItem
    property bool open: false
    property int gap: 6

    default property alias content: panel.data

    readonly property var window: anchorItem.QsWindow.window

    // Right edge of the panel lines up with the right edge of the item.
    property real rightMargin: 0

    function toggle() {
        open = !open;
    }

    onOpenChanged: {
        if (open && window)
            rightMargin = window.width - anchorItem.mapToItem(null, anchorItem.width, 0).x;
    }

    PanelWindow {
        visible: root.open
        screen: root.window?.screen ?? null
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "signalis-shield"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: root.open = false
        }
    }

    PanelWindow {
        id: panel

        visible: root.open
        screen: root.window?.screen ?? null
        anchors {
            top: true
            right: true
        }
        // Normal exclusion keeps it below the bar.
        margins.top: root.gap
        margins.right: root.rightMargin
        // Sized by its single visual child.
        implicitWidth: contentItem.children[0]?.implicitWidth ?? 0
        implicitHeight: contentItem.children[0]?.implicitHeight ?? 0
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "signalis-dropdown"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    }
}
