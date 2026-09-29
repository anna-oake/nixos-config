import QtQuick
import QtQuick.Window
import qs.auth

// Standalone native visual preview: no session lock, PAM, or greetd.
Window {
    id: root
    visible: true
    width: 1280
    height: 720
    title: "ElsterEye native preview — type or touch to move the eye"
    color: "black"
    ElsterEye {
        id: eye
        anchors.fill: parent
        typing: input.text.length > 0
        cursorTarget: Qt.point(prompt.x + cursor.x + 5, prompt.y + 9)
    }
    Rectangle {
        id: prompt
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.8
        width: 345; height: 54
        color: "#e6111827"
        border.color: "#792b32"
        Row {
            x: 18; y: 18
            spacing: 3
            Repeater {
                model: 24
                Rectangle {
                    required property int index
                    width: 10; height: 18
                    color: index < input.text.length ? "#b32936" : "transparent"
                    border.color: "#792b32"
                }
            }
        }
        Rectangle {
            id: cursor
            x: 18 + Math.min(input.cursorPosition, 23) * 13
            y: 18; width: 10; height: 18
            color: "transparent"
            border.color: "#ff5966"
        }
        TextInput {
            id: input
            width: 1; height: 1; opacity: 0
            focus: true
            echoMode: TextInput.Password
            Keys.onEscapePressed: text = ""
        }
    }
    ElsterEyeTouch {
        anchors.fill: parent
        z: 100
        avatar: eye
    }
}
