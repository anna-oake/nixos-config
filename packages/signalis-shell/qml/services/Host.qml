pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    readonly property string name: file.text().trim()

    FileView {
        id: file
        path: "/proc/sys/kernel/hostname"
        blockLoading: true
    }
}
