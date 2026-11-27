{
  stdenv,
  pkg-config,
  wrapGAppsHook4,
  gtk4,
  pipewire,
  sox,
}:

stdenv.mkDerivation {
  pname = "xun-peripherals";
  version = "0.1";
  src = ./main.c;
  dontUnpack = true;

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
    sox
  ];
  buildInputs = [ gtk4 ];

  buildPhase = ''
    runHook preBuild
    "$CC" -std=c11 -Wall -Wextra \
      -DPIPEWIRE_BIN='"${pipewire}/bin"' \
      -DTONE_DIR='"'$out/share/xun-peripherals'"' \
      "$src" -o xun-peripherals $(pkg-config --cflags --libs gtk4)
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 xun-peripherals "$out/bin/xun-peripherals"
    mkdir -p "$out/share/xun-peripherals"
    sox -n -r 48000 -c 1 tone.wav synth 0.7 sine 440 vol 0.1
    sox tone.wav "$out/share/xun-peripherals/left.wav" remix 1 0
    sox tone.wav "$out/share/xun-peripherals/right.wav" remix 0 1
    runHook postInstall
  '';
}
