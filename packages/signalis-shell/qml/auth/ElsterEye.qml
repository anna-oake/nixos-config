import QtQuick
import "EyeShape.js" as EyeShape

// Native port of SeasyecN’s upstream eye renderer, revision recorded in elstereye/README.md.
// Coordinates and layer sizes intentionally follow the original CSS viewport units.
Rectangle {
    id: root
    color: "#111827"
    clip: true

    property bool typing: false
    property point cursorTarget: Qt.point(width / 2, height * 0.8)
    property point idleTarget: Qt.point(0, 0)
    property bool touchActive: false
    property point touchPosition: Qt.point(0, 0)
    readonly property bool touchingEye: touchActive && eyeContains(touchPosition)
    readonly property bool watching: touchActive || typing || recovery.running
    readonly property point target: touchActive
        ? Qt.point(touchPosition.x - width / 2, touchPosition.y - height / 2)
        : typing
        ? Qt.point(cursorTarget.x - width / 2, cursorTarget.y - height / 2)
        : idleTarget
    readonly property int expression: target.y > 150 ? 5 : (target.y > 0 ? 4 : 0)
    property int blinkFrame: 0
    property int recoveryFrame: -1
    readonly property int frame: touchingEye ? 2 : recoveryFrame >= 0 ? recoveryFrame
        : blinkFrame === 1 || blinkFrame === 2 ? blinkFrame : expression

    function eyeContains(point) {
        const scale = Math.max(width / 1920, height * 1.02 / 1080);
        if (scale <= 0) return false;
        const left = (width - 1920 * scale) / 2;
        const top = (height * 1.02 - 1080 * scale) / 2 + breath;
        return EyeShape.contains((point.x - left) / scale, (point.y - top) / scale);
    }

    function beginTouch(point) {
        touchPosition = point;
        touchActive = true;
    }
    function moveTouch(point) { touchPosition = point; }
    function endTouch() { touchActive = false; }

    onTouchingEyeChanged: {
        if (touchingEye) {
            blink.stop();
            recovery.stop();
            blinkFrame = 0;
            recoveryFrame = -1;
        } else {
            recovery.restart();
        }
    }
    property real breath: 0
    property real hairMotion: 0

    // CSS's default ease is cubic-bezier(.25,.1,.25,1), not a sine wave.
    SequentialAnimation on breath {
        loops: Animation.Infinite
        NumberAnimation { to: -7; duration: 2500; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.25, 0.1, 0.25, 1, 1, 1] }
        NumberAnimation { to: 0; duration: 2500; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.25, 0.1, 0.25, 1, 1, 1] }
    }
    SequentialAnimation on hairMotion {
        loops: Animation.Infinite
        NumberAnimation { to: 1; duration: 2500; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.25, 0.1, 0.25, 1, 1, 1] }
        NumberAnimation { to: 0; duration: 2500; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.25, 0.1, 0.25, 1, 1, 1] }
    }

    Timer {
        id: blinkTimer
        interval: 3200 + Math.random() * 800
        running: root.visible && !root.touchingEye && !recovery.running
        repeat: true
        onTriggered: blink.restart()
    }
    onExpressionChanged: {
        blinkTimer.interval = 3200 + Math.random() * 800;
        if (root.visible && !root.touchingEye && !recovery.running) blinkTimer.restart();
    }
    SequentialAnimation {
        id: blink
        PauseAnimation { duration: 10 }
        PropertyAction { target: root; property: "blinkFrame"; value: 1 }
        PauseAnimation { duration: 70 }
        PropertyAction { target: root; property: "blinkFrame"; value: 2 }
        PauseAnimation { duration: 200 }
        PropertyAction { target: root; property: "blinkFrame"; value: 0 }
    }

    // Open briefly, then flutter three times before handing expression control
    // back to touch tracking, password tracking, or idle. A new poke interrupts it.
    SequentialAnimation {
        id: recovery
        PropertyAction { target: root; property: "recoveryFrame"; value: 0 }
        PauseAnimation { duration: 80 }
        SequentialAnimation {
            loops: 3
            PropertyAction { target: root; property: "recoveryFrame"; value: 1 }
            PauseAnimation { duration: 45 }
            PropertyAction { target: root; property: "recoveryFrame"; value: 2 }
            PauseAnimation { duration: 75 }
            PropertyAction { target: root; property: "recoveryFrame"; value: 0 }
            PauseAnimation { duration: 85 }
        }
        onStopped: root.recoveryFrame = -1
    }

    // Spend most idle time looking straight ahead; a glance lasts 0.6–1.3s.
    Timer {
        id: wander
        interval: 3000 + Math.random() * 5000
        running: root.visible && !root.watching
        onTriggered: {
            root.idleTarget = Qt.point((Math.random() - 0.5) * root.width * 0.45,
                (Math.random() - 0.5) * root.height * 0.25);
            returnGaze.restart();
        }
    }
    Timer {
        id: returnGaze
        interval: 600 + Math.random() * 700
        onTriggered: {
            root.idleTarget = Qt.point(0, 0);
            wander.interval = 3000 + Math.random() * 5000;
            wander.restart();
        }
    }
    onWatchingChanged: {
        returnGaze.stop();
        idleTarget = Qt.point(0, 0);
        if (!watching) wander.restart();
    }

    Image {
        width: root.width; height: root.height * 1.02; y: root.breath
        source: "elstereye/face.png"
        visible: root.frame !== 2
        fillMode: Image.PreserveAspectCrop
    }
    Item {
        x: root.width * 0.25; y: root.height * 0.25
        width: root.width * 0.5; height: root.height * 0.5
        z: 10
        // The closed expression is opaque and completely covers these layers.
        visible: root.frame !== 2
        Repeater {
            // Original stacking order, including the different highlight heights.
            model: [
                {name: "pupil_mask", vector: 5, h: 0.45, layer: 5},
                {name: "sensor", vector: 7.5, h: 0.45, layer: 6},
                {name: "pupil", vector: 5, h: 0.45, layer: 10},
                {name: "highlight_height", vector: 6, h: 0.48, layer: 10},
                {name: "highlight_low", vector: 4.5, h: 0.50, layer: 10},
                {name: "highlight_white", vector: 4.5, h: 0.45, layer: 10}
            ]
            Image {
                required property var modelData
                width: root.width * 0.45; height: root.height * modelData.h
                x: root.target.x / modelData.vector
                y: root.target.y / modelData.vector
                z: modelData.layer
                source: "elstereye/" + modelData.name + ".png"
                fillMode: Image.PreserveAspectFit
                Behavior on x { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
                Behavior on y { NumberAnimation { duration: 100; easing.type: Easing.Linear } }
            }
        }
    }
    // Build-time composition preserves base-mask -> expression draw order,
    // replacing two identically moving full-screen layers with one.
    // Keep every expression decoded; a blink never waits for an image load.
    Repeater {
        model: [0, 1, 2, 4, 5]
        Image {
            required property int modelData
            width: root.width; height: root.height * 1.02; y: root.breath; z: 30
            source: "elstereye/mask" + modelData + ".png"
            visible: root.frame === modelData
            fillMode: Image.PreserveAspectCrop
        }
    }
    Image {
        width: root.width * 1.03; height: root.height * 1.03
        x: -10 + root.hairMotion * 10; y: -root.hairMotion * 10; z: 30
        source: "elstereye/hair.png"
        fillMode: Image.PreserveAspectCrop
    }
    ElsterEyeCrt { anchors.fill: parent; z: 50 }
}
