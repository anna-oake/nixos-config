import QtQuick
import qs.config

// DIN condensed caps, as in the site mastheads.
Text {
    property int size: 20

    // Height of the capitals (DINish Condensed Bold: 0.691 em). Boxes centre on
    // this rather than the line box, which leaves room for accents above.
    readonly property real capHeight: size * 0.691

    // y that centres the capitals in a box of the given height.
    function capCentre(boxHeight) {
        return (boxHeight - capHeight) / 2 + capHeight - baselineOffset;
    }

    color: Theme.ink
    font.family: Theme.fontDisplay
    font.weight: Font.Bold
    font.pixelSize: size
    font.letterSpacing: size * 0.04
    font.capitalization: Font.AllUppercase
    textFormat: Text.PlainText
}
