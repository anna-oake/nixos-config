import QtQuick
import QtTest
import "../qml/auth"

Item {
    id: harness
    property var firstPoint: null
    width: 1280; height: 720
    ElsterEye { id: eye; anchors.fill: parent }
    ElsterEyeTouch { id: touch; anchors.fill: parent; avatar: eye }

    Connections {
        target: touch
        function onPressed(points) { harness.firstPoint = points[0]; }
    }
    TestCase {
        name: "ElsterEyeTouch"
        when: windowShown
        function init() {
            eye.typing = false;
            eye.cursorTarget = Qt.point(640, 600);
            eye.idleTarget = Qt.point(0, 0);
        }
        function cleanup() {
            // Lift all contacts even if an assertion interrupted a gesture.
            touchEvent(touch).release(0, touch).release(1, touch).release(2, touch).commit();
            wait(30);
            tryCompare(eye, "touchActive", false, 500);
            tryCompare(eye, "recoveryFrame", -1, 1500);
        }
        function test_touchOverridesKeyboardAndTracksDrag() {
            eye.typing = true;
            const sequence = touchEvent(touch);
            sequence.press(0, touch, 100, 100).commit();
            wait(30);
            tryCompare(eye, "touchActive", true);
            compare(eye.target.x, -540);
            compare(eye.target.y, -260);
            sequence.move(0, touch, 1100, 150).commit();
            wait(30);
            compare(eye.target.x, 460);
            compare(eye.target.y, -210);
            sequence.release(0, touch).commit();
            wait(30);
            tryCompare(eye, "touchActive", false);
            compare(eye.target.y, 240);
        }
        function test_onlyFirstFingerOwnsGesture() {
            const sequence = touchEvent(touch);
            sequence.press(0, touch, 100, 100).commit();
            wait(30);
            sequence.stationary(0).press(1, touch, 1000, 600).commit();
            wait(30);
            compare(eye.touchPosition.x, 100);
            sequence.stationary(0).move(1, touch, 640, 360).commit();
            wait(30);
            compare(eye.touchPosition.x, 100);
            verify(!eye.touchingEye);
            sequence.move(0, touch, 200, 150).stationary(1).commit();
            wait(30);
            compare(eye.touchPosition.x, 200);
            sequence.release(0, touch).stationary(1).commit();
            wait(30);
            tryCompare(eye, "touchActive", false, 500);
            sequence.move(1, touch, 600, 400).press(2, touch, 1100, 600).commit();
            wait(30);
            tryCompare(eye, "touchActive", false, 500);
            sequence.release(1, touch).release(2, touch).commit();
            wait(30);
            sequence.press(0, touch, 50, 50).commit();
            wait(30);
            compare(eye.touchActive, true);
            compare(eye.touchPosition.x, 50);
            sequence.release(0, touch).commit();
            wait(30);
        }
        function test_eyeClosesAndRecoversOnSlideOut() {
            const sequence = touchEvent(touch);
            sequence.press(0, touch, 640, 360).commit();
            wait(30);
            tryCompare(eye, "touchingEye", true);
            compare(eye.frame, 2);
            wait(400);
            compare(eye.frame, 2);
            sequence.move(0, touch, 100, 100).commit();
            wait(30);
            compare(eye.touchingEye, false);
            compare(eye.recoveryFrame, 0);
            tryCompare(eye, "recoveryFrame", 2, 500);
            tryCompare(eye, "recoveryFrame", -1, 1500);
            compare(eye.touchActive, true);
            sequence.release(0, touch).commit();
            wait(30);
        }
        function test_releasePokeAndInterruptRecovery() {
            const sequence = touchEvent(touch);
            sequence.press(0, touch, 640, 360).commit();
            wait(30);
            compare(eye.frame, 2);
            sequence.release(0, touch).commit();
            wait(30);
            tryCompare(eye, "touchActive", false, 500);
            compare(eye.recoveryFrame, 0);
            wait(140);
            sequence.press(0, touch, 640, 360).commit();
            wait(30);
            compare(eye.frame, 2);
            compare(eye.recoveryFrame, -1);
            sequence.release(0, touch).commit();
            wait(30);
            tryCompare(eye, "recoveryFrame", -1, 1500);
            compare(eye.target.x, 0);
            compare(eye.target.y, 0);
        }
        function test_cancelReleasesOwner() {
            // Cancellation is emitted by Qt when a surface/gesture loses touch.
            const sequence = touchEvent(touch);
            sequence.press(0, touch, 640, 360).commit();
            wait(30);
            compare(eye.frame, 2);
            // Pass a real TouchPoint into the typed Qt signal.
            touch.canceled([harness.firstPoint]);
            tryCompare(eye, "touchActive", false, 500);
            compare(touch.downIds.length, 0);
        }
        function test_shortDropoutKeepsGazeAndResumesWithNewId() {
            eye.typing = true;
            const sequence = touchEvent(touch);
            sequence.press(0, touch, 100, 100).commit();
            wait(30);
            sequence.release(0, touch).commit();
            wait(100);
            compare(eye.touchActive, true);
            compare(eye.target.x, -540);
            compare(eye.target.y, -260);
            sequence.press(1, touch, 200, 100).commit();
            wait(150);
            compare(eye.touchActive, true);
            compare(eye.touchPosition.x, 200);
            sequence.release(1, touch).commit();
            wait(100);
            compare(eye.touchActive, true);
            tryCompare(eye, "touchActive", false, 500);
            compare(eye.target.y, 240);
        }
        function test_shortPokeDropoutDoesNotReopenEye() {
            const sequence = touchEvent(touch);
            sequence.press(0, touch, 640, 360).commit();
            wait(30);
            sequence.release(0, touch).commit();
            wait(100);
            compare(eye.frame, 2);
            compare(eye.recoveryFrame, -1);
            sequence.press(1, touch, 640, 360).commit();
            wait(150);
            compare(eye.frame, 2);
            compare(eye.recoveryFrame, -1);
            sequence.release(1, touch).commit();
            wait(100);
            compare(eye.frame, 2);
            tryCompare(eye, "touchActive", false, 500);
            verify(eye.recoveryFrame >= 0);
            tryCompare(eye, "recoveryFrame", -1, 1500);
        }
        function test_hitRegionFollowsCropAndBreathing() {
            verify(eye.eyeContains(Qt.point(640, 360)));
            verify(!eye.eyeContains(Qt.point(100, 100)));
            harness.width = 800; harness.height = 1000;
            wait(30);
            verify(eye.eyeContains(Qt.point(400, 500)));
            verify(!eye.eyeContains(Qt.point(100, 100)));
            harness.width = 1280; harness.height = 720;
            wait(30);
        }
    }
}
