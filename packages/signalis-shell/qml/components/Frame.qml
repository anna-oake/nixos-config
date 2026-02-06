import QtQuick
import qs.config

// Hairline panel. With a label it gets the LSTR treatment: a light tab with
// dark caps sitting on the top edge.
Item {
    id: root

    property string label: ""
    property color borderColor: Theme.line
    property color fill: Theme.bg
    property color tabColor: Theme.ink
    property int padding: 12
    property int bottomPadding: padding

    default property alias content: body.data

    readonly property real tabInset: label !== "" ? tab.height / 2 : 0

    implicitWidth: body.childrenRect.width + padding * 2
    // The tab straddles the top edge: half above the box, half inside it above the content.
    implicitHeight: body.childrenRect.height + padding + bottomPadding + tabInset * 2

    Rectangle {
        id: box
        anchors.fill: parent
        anchors.topMargin: root.tabInset
        color: root.fill
        border.width: 1
        border.color: root.borderColor
    }

    Rectangle {
        id: tab
        visible: root.label !== ""
        x: 12
        width: tabText.implicitWidth + 14
        height: tabText.implicitHeight + 4
        color: root.tabColor

        Txt {
            id: tabText
            anchors.centerIn: parent
            text: root.label
            caps: true
            color: Theme.bg
        }
    }

    Item {
        id: body
        anchors.fill: box
        anchors.margins: root.padding
        anchors.topMargin: root.padding + root.tabInset
        anchors.bottomMargin: root.bottomPadding
    }
}
