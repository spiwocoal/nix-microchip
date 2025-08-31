# FIXME: importing this from a level up doesn' work for some reason...
pkgs: rec {
  xc8_3_00 = pkgs.callPackage ./3.00.nix {};
  xc8 = xc8_3_00; #i.e. default to latest
}
