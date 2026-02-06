import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// Polkit agent: privilege prompts in the same frame as the lock screen.
Scope {
    id: root

    readonly property var flow: agent.flow
    property bool denied: false

    PolkitAgent {
        id: agent
    }

    Connections {
        target: root.flow

        function onAuthenticationFailed() {
            root.denied = true;
            secret.clear();
            deniedTimer.restart();
        }
    }

    Timer {
        id: deniedTimer
        interval: 900
        onTriggered: root.denied = false
    }

    PanelWindow {
        visible: agent.isActive
        screen: {
            const focused = Niri.workspaces.find(w => w.is_focused);
            return Quickshell.screens.find(s => s.name === focused?.output) ?? Quickshell.screens[0];
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: Theme.alpha(Theme.bg, 0.75)
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "signalis-polkit"
        WlrLayershell.keyboardFocus: agent.isActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onVisibleChanged: if (visible) {
            secret.clear();
            secret.grab();
        }

        Frame {
            anchors.centerIn: parent
            width: 460
            height: implicitHeight
            label: "Authorization"
            borderColor: root.denied ? Theme.red : Theme.lineStrong
            padding: 18

            Column {
                width: 460 - 36
                spacing: 14

                Txt {
                    width: parent.width
                    text: root.flow?.message ?? ""
                    color: Theme.inkBright
                    wrapMode: Text.Wrap
                }

                Row {
                    spacing: 8

                    Txt {
                        text: "IDENT"
                        color: Theme.muted
                    }

                    Txt {
                        text: root.flow?.selectedIdentity?.displayName ?? ""
                        color: Theme.ink
                    }
                }

                Secret {
                    id: secret
                    busy: root.flow ? !root.flow.isResponseRequired && !root.denied : false
                    error: root.denied
                    onAccepted: if (root.flow?.isResponseRequired) root.flow.submit(text)
                    onCancelled: root.flow?.cancelAuthenticationRequest()
                }

                Txt {
                    text: root.denied ? "ACCESS DENIED" : (root.flow?.supplementaryMessage || (root.flow?.isResponseRequired ? (root.flow.inputPrompt || "PASSWORD").toUpperCase() : "VERIFYING"))
                    color: root.denied || root.flow?.supplementaryIsError ? Theme.red : Theme.muted
                }

                Row {
                    spacing: 6

                    Readout {
                        value: "CANCEL"
                        frameColor: Theme.line
                        onClicked: root.flow?.cancelAuthenticationRequest()
                    }

                    Readout {
                        value: "CONFIRM"
                        frameColor: Theme.redBorder
                        onClicked: secret.accepted()
                    }
                }
            }
        }
    }
}
