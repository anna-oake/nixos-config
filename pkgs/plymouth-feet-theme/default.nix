{
  stdenvNoCC,
  fetchgit,
  lib,
}:

stdenvNoCC.mkDerivation {
  pname = "plymouth-feet-theme";
  version = "1.0.0";

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/share/plymouth/themes/feet
    cp -r ${./feet}/* $out/share/plymouth/themes/feet
    find $out/share/plymouth/themes/ -name \*.plymouth -exec sed -i "s@\/usr\/@$out\/@" {} \;
  '';

  meta = {
    description = "Feet Plymouth boot splash";
    platforms = lib.platforms.linux;
  };
}
