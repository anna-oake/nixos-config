import QtQuick

// Faint CRT scanlines: a 1px line every 4px, as on the sites.
Item {
    id: root

    property real strength: 0.012

    clip: true

    Column {
        Repeater {
            model: Math.ceil(root.height / 4)

            Item {
                width: root.width
                height: 4

                Rectangle {
                    y: 3
                    width: parent.width
                    height: 1
                    color: Qt.rgba(1, 1, 1, root.strength)
                }
            }
        }
    }
}
