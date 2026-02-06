import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// Background layer. niri places the "wallpaper" namespace behind the overview too.
PanelWindow {
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: Theme.bg
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "wallpaper"

    Image {
        anchors.fill: parent
        source: Theme.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: width * (Screen.devicePixelRatio || 1)
    }
}
