import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Row {
    id: root

    required property var bar

    spacing: 8
    rightPadding: 6

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item

            required property SystemTrayItem modelData

            width: 14
            height: 14
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            function openMenu() {
                const p = item.mapToItem(null, 0, item.height + 8);
                modelData.display(root.bar, p.x, p.y);
            }

            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton)
                    modelData.secondaryActivate();
                else if (mouse.button === Qt.RightButton || modelData.onlyMenu)
                    modelData.hasMenu && openMenu();
                else
                    modelData.activate();
            }

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
                asynchronous: true
            }
        }
    }
}
