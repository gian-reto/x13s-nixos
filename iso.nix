{
  config,
  lib,
  ...
}:

{
  image.baseName =
    let
      deviceTreeBaseName = builtins.elemAt (lib.splitString "." (builtins.baseNameOf config.hardware.deviceTree.name)) 0;
    in
    lib.mkForce "nixos-${deviceTreeBaseName}";

  boot.supportedFilesystems.zfs = lib.mkForce false;
  boot.supportedFilesystems.cifs = lib.mkForce false;

  hardware.enableAllHardware = lib.mkForce false;

  # For some reason the adsp booting up messes with USB boot, so disable it for the ISO.
  boot.blacklistedKernelModules = [ "qcom_q6v5_pas" ];

  nix.registry.x13s-nixos = {
    from = {
      type = "indirect";
      id = "x13s-nixos";
    };
    to = {
      type = "path";
      path = ./.;
    };
  };

  systemd.tmpfiles.rules = [ "L /x13s-nixos - - - - ${./.}" ];
}
