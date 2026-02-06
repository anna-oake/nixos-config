import QtQuick
import qs.components
import qs.config
import qs.services

// The site selector: DIN numbers, the active one as a solid red block.
Row {
    id: root

    property string output: ""

    spacing: 2

    Repeater {
        model: Niri.workspacesOn(root.output)

        Rectangle {
            id: cell

            required property var modelData
            readonly property bool active: modelData.is_active
            property bool blinkOn: true

            width: label.implicitWidth + 16
            height: 24
            color: active ? (mouse.containsMouse ? Theme.redHover : Theme.redDeep) : "transparent"
            border.width: 1
            border.color: active ? color : (mouse.containsMouse ? Theme.red : "transparent")

            Din {
                id: label
                anchors.horizontalCenter: parent.horizontalCenter
                y: capCentre(cell.height)
                text: cell.modelData.name ?? cell.modelData.idx
                color: cell.active ? "#000000" : (cell.modelData.is_urgent && !cell.blinkOn ? Theme.redDark : (cell.modelData.is_urgent ? Theme.red : (mouse.containsMouse ? Theme.ink : Theme.muted)))
            }

            Timer {
                running: cell.modelData.is_urgent && !cell.active
                repeat: true
                interval: 500
                onTriggered: cell.blinkOn = !cell.blinkOn
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Niri.action("focus-workspace", String(cell.modelData.idx))
            }
        }
    }
}
