{
  lib,
  pkgs,
  ...
}: let
  sources = import ../npins;

  linux_x13s_pkg = {
    version,
    buildLinux,
    ...
  } @ args:
    buildLinux (
      args
      // {
        modDirVersion = version;

        # See:
        # - https://codeberg.org/steveej/nixos-x13s/commit/f691c125485b6764ebef0b9f148613d79de95525
        # - https://github.com/NixOS/nixpkgs/pull/345534/commits/88746a794398da15142f91d42c829a4336616596#diff-764a10a0418846e85912fafd206b2502db65dbbd8c59adc0532b50d05c438d21R993-R998
        structuredExtraConfig = with lib.kernel; {
          MODULE_COMPRESS = yes;
          MODULE_COMPRESS_ALL = yes;
          MODULE_COMPRESS_XZ = yes;
        };

        extraMeta.branch = lib.versions.majorMinor version;
      }
    );
in {
  linux_jhovold = pkgs.callPackage linux_x13s_pkg {
    src = sources.linux-jhovold;
    version = "6.12.0";
    defconfig = "johan_defconfig";
  };

  # Video acceleration support (venus) & gpu firmware.
  graphics-firmware = let
    git-src = pkgs.fetchFromGitHub {
      owner = "ironrobin";
      repo = "x13s-alarm";
      rev = "ea9ce5f";
      hash = "sha256-h6b3zyNcgK3L8bs8Du+3PXmZ3hG+ht6CsGRObDvEYqA=";
    };
  in
    pkgs.runCommand "graphics-firmware" {} ''
      mkdir -pv "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX"
      cp -fv "${git-src}/x13s-firmware/qcvss8280.mbn" "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX"
      cp -fv "${git-src}/x13s-firmware/a690_gmu.bin" "$out/lib/firmware/qcom"
    '';

  bluetooth-firmware = let
    git-src = pkgs.fetchgit {
      url = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware";
      rev = "77a11ffc5a0aaaadc870793d02f6c6781ee9f598";
      hash = "sha256-edcLKEN5Nq0Gw+hS1bVfiTX7wDn9MzuZAdASo4EQcBo=";
    };
  in
    pkgs.runCommand "bluetooth-firmware" {} ''
      mkdir -pv "$out/lib/firmware/qca"
      cp -fv "${git-src}/qca/hpnv21.b8c" "$out/lib/firmware/qca"
      cp -fv "${git-src}/qca/hpnv21g.b8c" "$out/lib/firmware/qca"
    '';
}
