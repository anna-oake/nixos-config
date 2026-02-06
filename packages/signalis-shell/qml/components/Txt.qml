import QtQuick
import qs.config

// Departure Mono, snapped to whole multiples of its 11px grid in device pixels
// so it stays crisp under fractional output scales.
Text {
    property int grid: 1
    property bool caps: false

    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1

    color: Theme.ink
    font.family: Theme.fontUi
    font.pointSize: 0.75 * 11 * grid * Math.max(1, Math.round(dpr)) / dpr
    font.hintingPreference: Font.PreferFullHinting
    font.kerning: false
    font.capitalization: caps ? Font.AllUppercase : Font.MixedCase
    renderType: Text.NativeRendering
    textFormat: Text.PlainText
}
