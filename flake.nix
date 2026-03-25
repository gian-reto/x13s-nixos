{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      eachBuildSystem =
        f:
        builtins.zipAttrsWith (_: nixpkgs.lib.listToAttrs) (
          map
            (
              buildSystem:
              builtins.mapAttrs (_: nixpkgs.lib.nameValuePair buildSystem) (f buildSystem)
            )
            [
              "x86_64-linux"
              "aarch64-linux"
            ]
        );

      mkPatchedNixpkgs =
        buildSystem:
        let
          pkgsUnpatched = nixpkgs.legacyPackages.${buildSystem};
        in
        (pkgsUnpatched.applyPatches {
          name = "nixpkgs-patched";
          src = nixpkgs;
          patches = [
            (pkgsUnpatched.fetchpatch {
              url = "https://github.com/NixOS/nixpkgs/commit/de1fdb6310af8f70c98746ba4550dc2799a03621.patch";
              hash = "sha256-brqJxblmqWFAk8JgxmxXeHoiaWiQtsCsOzht/WlH5eE=";
            })
            ./nixpkgs-efi-shell.patch
          ];
        }).overrideAttrs {
          allowSubstitutes = true;
        };

      mkPkgs =
        buildSystem:
        import (mkPatchedNixpkgs buildSystem) {
          overlays = [ self.overlays.default ];
          localSystem.system = buildSystem;
          crossSystem.system = "aarch64-linux";
          allowUnsupportedSystem = true;
        };

      mkIso =
        buildSystem:
        nixpkgs.lib.nixosSystem {
          modules = [
            "${mkPatchedNixpkgs buildSystem}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            ./iso.nix
            self.nixosModules.default
            {
              nixpkgs.pkgs = mkPkgs buildSystem;
              hardware.lenovo-thinkpad-x13s.enable = true;
            }
            (
              { lib, pkgs, ... }:
              lib.mkIf (pkgs.stdenv.buildPlatform != pkgs.stdenv.hostPlatform) {
                isoImage.storeContents = [ (mkPatchedNixpkgs buildSystem) ];

                system.systemBuilderCommands = ''
                  echo -n "${pkgs.stdenv.buildPlatform.system}" > $out/build-system
                '';
              }
            )
          ];
        };

      mkExample =
        buildSystem:
        nixpkgs.lib.nixosSystem {
          modules = [
            self.nixosModules.default
            {
              nixpkgs.pkgs = mkPkgs buildSystem;
              hardware.lenovo-thinkpad-x13s.enable = true;

              fileSystems."/" = {
                device = "/dev/disk/by-label/root";
                fsType = "ext4";
              };

              fileSystems."/boot" = {
                device = "/dev/disk/by-label/SYSTEM_DRV";
                fsType = "vfat";
              };
            }
          ];
        };
    in
    (import ./default.nix)
    // {
      nixosConfigurations = self.nixosConfigurationsForBuildSystem.aarch64-linux;

      overlays = {
        default = import ./packages/overlay.nix;
      };
    }
    // eachBuildSystem (
      buildSystem:
      let
        pkgs = mkPkgs buildSystem;
        iso = mkIso buildSystem;
        uefiPackages = import ./packages/part.nix { inherit pkgs; };
      in
      {
        nixosConfigurationsForBuildSystem = {
          example = mkExample buildSystem;
          iso = iso;
        };

        packages = {
          iso = iso.config.system.build.isoImage;
          kernel = pkgs.x13s-linux.kernel;
          inherit (uefiPackages) uefi;
        };
      }
    );
}
