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

    // By default the panel's right edge lines up with the item's; centred puts
    // the panel's middle under the item's, kept on screen.
    property bool centered: false
    // The item's right edge or middle in window coordinates, taken on open.
    property real anchorX: 0
    readonly property real rightMargin: {
        const width = window?.width ?? 0;
        if (!centered)
            return width - anchorX;
        return Math.max(gap, Math.min(width - panel.implicitWidth - gap, width - anchorX - panel.implicitWidth / 2));
    }

    function toggle() {
        open = !open;
    }

    onOpenChanged: {
        if (open && window)
            anchorX = anchorItem.mapToItem(null, centered ? anchorItem.width / 2 : anchorItem.width, 0).x;
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
