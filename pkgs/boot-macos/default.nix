{
  stdenvNoCC,
  writeShellApplication,
  makeDesktopItem,
  lib,
  asahi-bless,
}:
let
  script = writeShellApplication {
    name = "boot-macos";
    text = builtins.readFile ./boot-macos.sh;

    runtimeInputs = [
      asahi-bless
    ];
  };

  desktop = makeDesktopItem {
    name = "Boot macOS";
    desktopName = "Boot macOS";
    comment = "Program that reboots into macOS";
    categories = [ "Utility" ];
    icon = ./apple-logo.png;
    exec = "pkexec ${lib.getExe script}";
  };
in
stdenvNoCC.mkDerivation {
  name = "boot-macos";

  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/applications/
    cp ${lib.getExe script} $out/bin
    cp ${desktop}/share/applications/* $out/share/applications
  '';

  meta = with lib; {
    platforms = with platforms; linux;
  };
}
