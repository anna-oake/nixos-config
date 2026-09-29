These original PNG layers are from https://api.github.com/repositories/1136239446
at commit 13eb75c8021cd697f63faf2b74f0098330795a70 (SeasyecN).
Upstream credits the character inspiration to Signalis / rose-engine.

ElsterEye.qml preserves the upstream layer geometry, 100ms linear parallax,
5s CSS ease breathing/hair motion, and 10/80/280ms blink sequence. Normal
blinks now occur every 3.2–4 seconds, half as often as the original. Touch
recovery still uses three quick blinks.

The build precomposes blink0 beneath each expression into mask0/1/2/4/5.png.
Their size and movement are identical, so this removes a full-screen blend
pass without changing the artwork or layer motion. Original assets remain
on disk for provenance and the eye hit region.

ElsterEyeCrt.qml renders scanlines, noise, and vignette as one transparent
native ShaderEffect overlay. elstereye-crt.frag combines them in the original
source-over order, without capturing the background to an offscreen texture.
The small 256px noise tile is generated once, then randomly offset each frame.
The build compiles the shader with Qt's qsb tool. This removes two full-screen
CRT blend passes and the full-screen Canvas textures on the GPU backend.
Qt's software backend loads ElsterEyeCrtSoftware.qml instead, preserving the
previous Canvas implementation. No renderer override is imposed on the shell.

Intentional interaction changes: idle glances instead of mouse tracking,
password cursor geometry as the typing target, touch interactions, and
authorization below the eye. There is no browser, HTML, React, network request,
or password access in the renderer.

After building/installing the package, use signalis-eye-preview for a safe
visual preview without locking or authenticating. The preview must use the
built package because expression masks and the .qsb shader are build outputs.
Compare at the same logical viewport size as the upstream demo. Exercise
password insertion, deletion, arrow keys, Home/End, clearing, and touch, then
leave it idle to check glance/return and blink sequences.

Touch takes priority over password tracking, which takes priority over idle.
The first contact owns the gesture; subsequent contacts are ignored until all
contacts lift. Release is debounced for 200ms to bridge brief touchscreen
dropouts without resetting gaze or reopening a poked eye. Touching the open-eye
aperture closes it. Leaving the aperture or lifting triggers recovery blinks;
touching it again interrupts recovery. EyeShape.js traces blink0.png's aperture
and maps it through the same cover/crop and breathing transform as the face.

Native Qt touch regression tests are in packages/signalis-shell/tests. For a
headless fixture, copy the built package's share/signalis-shell directory to
<fixture>/qml and the tests directory to <fixture>/tests, then run:
  QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qmltestrunner -input <fixture>/tests
QtQuick/QtTest must be on the runner's import path. The tests use synthetic
touch events without accessing authentication. Shader visual verification
requires an OpenGL/Vulkan backend, including Mesa llvmpipe in a virtual display.
