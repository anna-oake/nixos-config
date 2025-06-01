{ stdenvNoCC, fetchzip }:

stdenvNoCC.mkDerivation rec {
  pname = "ilya-birman-typography-layout";
  version = "3.9";

  src = fetchzip {
    url = "https://ilyabirman.ru/typography-layout/download/ilya-birman-typolayout-${version}-mac.zip";
    hash = "sha256-pJx5BG/ASVPZjo9lfxdYpyfz8qZsZmlLF9Bt2LTSt/U=";
    stripRoot = false;
  };

  patches = [
    ./trim-names.patch
  ];

  installPhase = ''
    mkdir -p "$out/Library/Keyboard Layouts"
    cp -r "Ilya Birman Typography Layout.bundle" "$out/Library/Keyboard Layouts/"
  '';

  passthru.layouts = [
    {
      id = -9876;
      name = "English";
    }
    {
      id = -31553;
      name = "Russian";
    }
  ];
}
