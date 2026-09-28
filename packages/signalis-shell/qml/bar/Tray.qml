import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Row {
    id: root

    spacing: 8
    rightPadding: 6

    TrayMenu {
        id: menu
        anchorItem: root
    }

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item

            required property SystemTrayItem modelData

            width: 14
            height: 14
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            function openMenu() {
                menu.show(modelData, item);
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
