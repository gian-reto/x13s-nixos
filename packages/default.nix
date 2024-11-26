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

  graphics-firmware = let
    gpu-src = pkgs.fetchurl {
      url = "https://download.lenovo.com/pccbbs/mobiles/n3hdr20w.exe";
      hash = "sha256-Jwyl9uKOnjpwfHd+VaGHjYs9x8cUuRdFCERuXqaJwEY=";
    };
  in
    pkgs.runCommand "graphics-firmware" {} ''
      mkdir -vp "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX"
      ${lib.getExe pkgs.innoextract} ${gpu-src}
      cp -v code\$GetExtractPath\$/*/*.mbn "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX/"
    '';
}
