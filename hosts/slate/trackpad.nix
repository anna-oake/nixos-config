{
  config,
  lib,
  pkgs,
  ...
}:
let
  niri = pkgs.niri-stable.overrideAttrs (old: {
    # Continuous scrolling owns its momentum in libinput. Forward its stop
    # events as well as finger stops so clients can end the scroll sequence.
    patches = (old.patches or [ ]) ++ [ ./trackpad/niri.patch ];
  });
  macosLibinput = pkgs.libinput.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./trackpad/libinput.patch ];
    postPatch = (old.postPatch or "") + ''
      cp ${./trackpad/macos-pointer.h} src/slate-macos-pointer.h
      cp ${./trackpad/macos-scroll.h} src/slate-macos-scroll.h
      cp ${./trackpad/macos-scroll.c} src/slate-macos-scroll.c
    '';
  });
in
{
  # The systemd hwdb rule for the 15-inch SL3 also matches this 13.5-inch
  # machine, setting X/Y resolution to 39/37 and shrinking its reported size
  # to 57 x 39 mm. This device's HID descriptor specifies 2227 x 1459 units
  # over 111.3 x 72.9 mm: approximately 20 units/mm on both axes.
  services.udev.extraHwdb = ''
    evdev:name:Microsoft Surface 045E:09AF Touchpad:dmi:*:skuSurface_Laptop_3_18671868:*
     EVDEV_ABS_00=::20
     EVDEV_ABS_01=::20
     EVDEV_ABS_35=::20
     EVDEV_ABS_36=::20
  '';

  # The kernel exposes this keyboard without the "Keyboard" suffix required
  # by libinput's upstream Surface rule. Pair it with the internal touchpad so
  # disable-while-typing can work.
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Surface Laptop 3 internal keyboard]
    MatchName=Microsoft Surface 045E:09AE
    MatchVendor=0x045E
    MatchProduct=0x09AE
    MatchUdevType=keyboard
    MatchDMIModalias=dmi:*:skuSurface_Laptop_3_18671868:*
    AttrKeyboardIntegration=internal
  '';

  home-manager.users.${config.me.username}.programs.niri.settings.input.touchpad = {
    accel-profile = "adaptive";
    dwt = true;
    # This Mac has three-finger drag enabled, but tap-and-drag disabled.
    drag = false;
    drag-lock = false;
  };

  # The libinput ABI is unchanged. Bind only this compositor to the modified
  # library, including its systemd session entry point.
  programs.niri.package = lib.mkForce (
    pkgs.runCommand "${niri.name}-macos-input"
      {
        nativeBuildInputs = [ pkgs.patchelf ];
        inherit (niri) meta version;
        passthru = niri.passthru or { };
      }
      ''
        cp -a ${niri} $out
        chmod -R u+w $out
        patchelf --print-needed $out/bin/niri | grep -Fxq libinput.so.10
        patchelf --replace-needed libinput.so.10 ${lib.getLib macosLibinput}/lib/libinput.so.10 $out/bin/niri
        substituteInPlace $out/lib/systemd/user/niri.service \
          --replace-fail ${niri}/bin/niri $out/bin/niri
      ''
  );
}
