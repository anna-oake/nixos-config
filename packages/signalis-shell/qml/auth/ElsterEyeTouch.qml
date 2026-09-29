import QtQuick

// Native touch only: no mouse synthesis and no keyboard focus changes.
// Secondary contacts stay ignored until the whole gesture has ended, including
// when the owner lifts first; an already-held finger never becomes the owner.
MultiPointTouchArea {
    id: root
    required property ElsterEye avatar
    property int ownerId: -1
    property var downIds: []
    mouseEnabled: false

    // Some touch panels briefly report a release during a drag. Keep the last
    // gaze/closed-eye state until release is stable; a fresh first contact
    // resumes it immediately, even when the hardware assigns a new point ID.
    Timer {
        id: releaseHold
        interval: 200
        onTriggered: root.avatar.endTouch()
    }

    onPressed: points => {
        if (downIds.length === 0 && points.length > 0) {
            releaseHold.stop();
            ownerId = points[0].pointId;
            avatar.beginTouch(Qt.point(points[0].x, points[0].y));
        }
        downIds = downIds.concat(Array.from(points, point => point.pointId));
    }
    onUpdated: points => {
        for (const point of points) {
            if (point.pointId === ownerId) {
                avatar.moveTouch(Qt.point(point.x, point.y));
                break;
            }
        }
    }
    function releasePoints(points) {
        const released = Array.from(points, point => point.pointId);
        if (released.includes(ownerId)) {
            ownerId = -1;
            releaseHold.restart();
        }
        downIds = downIds.filter(id => !released.includes(id));
    }
    onReleased: points => releasePoints(points)
    onCanceled: points => releasePoints(points)
    onGestureStarted: gesture => gesture.grab()
    Component.onDestruction: if (avatar) avatar.endTouch()
}
