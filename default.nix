{
  nixosModules = {
    default =
      { ... }:
      {
        imports = [
          ./modules/common.nix
          ./modules/x13s.nix
        ];

        nixpkgs.overlays = [ (import ./packages/overlay.nix) ];
      };

    x13s =
      { ... }:
      {
        imports = [
          ./modules/common.nix
          ./modules/x13s.nix
        ];

        nixpkgs.overlays = [ (import ./packages/overlay.nix) ];
      };
  };
}
