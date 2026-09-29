import QtQuick
import QtQuick.Window

// One native blend pass for all three CRT effects. Software Qt retains the
// original Canvas renderer; its full-screen textures are never loaded on GPU.
Item {
    id: root
    readonly property bool softwareRenderer: GraphicsInfo.api === GraphicsInfo.Software

    Loader {
        anchors.fill: parent
        active: root.softwareRenderer
        source: "ElsterEyeCrtSoftware.qml"
    }
    Loader {
        anchors.fill: parent
        active: !root.softwareRenderer
        sourceComponent: Component {
            Item {
                id: gpu
                Canvas {
                    id: noise
                    width: 256; height: 256
                    property string tileSource: ""
                    property bool exporting: false
                    visible: tileSource === ""
                    antialiasing: true
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.fillStyle = "rgba(255,255,255,0.08)";
                        for (let i = 0; i < 500; ++i)
                            ctx.fillRect(Math.random() * 256, Math.random() * 256, 4, 4);
                    }
                    onPainted: if (!exporting && tileSource === "") {
                        exporting = true;
                        Qt.callLater(() => { tileSource = toDataURL("image/png"); });
                    }
                }
                Image {
                    id: noiseImage
                    visible: false
                    source: noise.tileSource
                    sourceSize: Qt.size(256, 256)
                    smooth: true
                }
                ShaderEffect {
                    id: effect
                    anchors.fill: parent
                    property var noiseTexture: noiseImage
                    property size viewportSize: Qt.size(width, height)
                    property point noiseOffset: Qt.point(0, 0)
                    property real pixelHeight: 1 / Screen.devicePixelRatio
                    fragmentShader: "elstereye-crt.frag.qsb"
                }
                FrameAnimation {
                    running: gpu.visible
                    onTriggered: effect.noiseOffset = Qt.point(
                        Math.floor(Math.random() * 256), Math.floor(Math.random() * 256))
                }
            }
        }
    }
}
