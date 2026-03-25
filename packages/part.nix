{pkgs}: let
  uefi = pkgs.callPackage ./uefi.nix {};
in {
  inherit uefi;
}
