pragma Singleton
import QtQuick
import Quickshell

// The session is frozen while asleep, so a stalled heartbeat means the machine
// has just woken up. Input arriving right then is the press that woke it.
Singleton {
    id: root

    property real lastTick: Date.now()
    property real resumedAt: 0
    property bool wakeKeyTaken: false

    signal resumed

    function tick() {
        const now = Date.now();
        if (now - lastTick > 3000) {
            resumedAt = now;
            wakeKeyTaken = false;
            resumed();
        }
        lastTick = now;
    }

    // Checks the heartbeat itself: the wake press can arrive before the timer
    // has fired after resume.
    function justResumed(window: int): bool {
        tick();
        return Date.now() - resumedAt < window;
    }

    // True for the first key press right after a resume only, so typing can
    // start straight away.
    function takeWakeKey(): bool {
        if (wakeKeyTaken || !justResumed(500))
            return false;
        wakeKeyTaken = true;
        return true;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.tick()
    }
}
