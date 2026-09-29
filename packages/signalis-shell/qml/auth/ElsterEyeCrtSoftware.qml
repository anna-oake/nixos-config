import QtQuick

// Same CRT constants and draw order as Crt.tsx. Only the grain tile moves each
// frame; scanlines and vignette are rasterized once per resize, on the CPU.
Item {
    id: root
    clip: true
    Canvas {
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = "rgba(0,0,0,0.15)";
            for (let y = 0; y < height; y += 3) ctx.fillRect(0, y, width, 1);
        }
    }
    Canvas {
        id: noise
        width: 256; height: 256
        // Export once, then normalize the image to the web's 256px tile size.
        // Qt captures at screen DPR (384px at Slate's 1.5x scale), but Image.Tile
        // treats bitmap pixels as logical pixels unless sourceSize is explicit.
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
            // toDataURL can flush painting and emit painted again; guard it and
            // export after the paint callback has returned.
            exporting = true;
            Qt.callLater(() => { tileSource = toDataURL("image/png"); });
        }
    }
    Image {
        id: grain
        width: root.width + 256; height: root.height + 256
        source: noise.tileSource
        sourceSize: Qt.size(256, 256)
        fillMode: Image.Tile
        // Match browser canvas filtering when logical pixels are scaled by DPR.
        smooth: true
    }
    FrameAnimation {
        running: root.visible
        onTriggered: {
            grain.x = Math.floor(Math.random() * 256) - 256;
            grain.y = Math.floor(Math.random() * 256) - 256;
        }
    }
    Canvas {
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const gradient = ctx.createRadialGradient(width / 2, height / 2, height / 3,
                width / 2, height / 2, height);
            gradient.addColorStop(0, "rgba(0,0,0,0)");
            gradient.addColorStop(1, "rgba(0,0,0,0.9)");
            ctx.fillStyle = gradient;
            ctx.fillRect(0, 0, width, height);
        }
    }
}
