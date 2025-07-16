final: prev:
let
  mkPackage = name: {
    inherit name;
    value = final.callPackage ./${name} { };
  };
  names = builtins.attrNames (builtins.readDir ./.);
in
builtins.listToAttrs (map mkPackage names)
