//@ pragma IgnoreSystemSettings

import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import Quickshell.Wayland
import qs.auth
import qs.services

// greetd greeter, run inside a throwaway niri by the NixOS module.
// SIGNALIS_USER picks the account, SIGNALIS_SESSION the command to launch.
ShellRoot {
    id: root

    readonly property string user: Quickshell.env("SIGNALIS_USER") ?? ""
    readonly property string session: Quickshell.env("SIGNALIS_SESSION") ?? "niri-session"

    property string password: ""
    property string status: ""
    property bool error: false
    property bool busy: false

    function submit(value) {
        password = value;
        busy = true;
        Greetd.createSession(user);
    }

    function fail(message) {
        busy = false;
        error = true;
        status = message || "Access denied";
        password = "";
        Greetd.cancelSession();
        errorTimer.restart();
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                Greetd.respond(root.password);
                root.password = "";
            } else if (error) {
                root.fail(message);
            }
        }

        function onAuthFailure(message) {
            root.fail("Access denied");
        }

        function onReadyToLaunch() {
            root.status = "Starting session";
            Greetd.launch(root.session.split(" "));
        }

        function onError(message) {
            root.fail(message);
        }
    }

    Timer {
        id: errorTimer
        interval: 1200
        onTriggered: {
            root.error = false;
            root.status = "";
            for (const surface of surfaces.instances)
                surface.screen_.reset();
        }
    }

    Variants {
        id: surfaces
        model: Quickshell.screens

        PanelWindow {
            required property ShellScreen modelData
            property alias screen_: auth

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "black"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            AuthScreen {
                id: auth
                anchors.fill: parent
                mode: "Login"
                host: Host.name.toUpperCase()
                user: root.user
                busy: root.busy
                error: root.error
                status: root.busy ? "Verifying" : root.status
                onSubmitted: password => root.submit(password)
            }
        }
    }
}
