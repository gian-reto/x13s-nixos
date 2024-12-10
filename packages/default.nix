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

        # See:
        # - https://github.com/NixOS/nixpkgs/issues/351302
        # - https://github.com/kuruczgy/x1e-nixos-config/issues/32
        # - https://github.com/jollheef/nixos-image-thinkpad-t14s-gen6/blob/0047776a64e5636b43334b6990c6164d8a53921e/kernel.nix#L62
        kernelPatches = [
          {
            name = "drm/panic: Select ZLIB_DEFLATE for DRM_PANIC_SCREEN_QR_CODE";
            patch = pkgs.fetchurl {
              url = "https://lore.kernel.org/linux-kernel/20241003230734.653717-1-ojeda@kernel.org/raw";
              hash = "sha256-qZTP9o0Pel9M1Y9f/31SZbOJxeM0j28P94EUXa83m+Q=";
            };
          }
        ];

        extraMeta.branch = lib.versions.majorMinor version;
      }
    );

  ironrobin-git-src = pkgs.fetchFromGitHub {
    owner = "ironrobin";
    repo = "x13s-alarm";
    rev = "ea9ce5f";
    hash = "sha256-h6b3zyNcgK3L8bs8Du+3PXmZ3hG+ht6CsGRObDvEYqA=";
  };

  linux-firmware-git-src = pkgs.fetchgit {
    url = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware";
    # `linux-firmware-20241210`: https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tag/?h=20241210.
    rev = "7acec9a736995f10d1b783753ac9d3d2b8cad5a8";
    hash = "sha256-z/YrFyL7Ee0bfwkLj5l1Ei3neMRS5ZAu76MA7T+48+g=";
  };
in {
  linux_jhovold = pkgs.callPackage linux_x13s_pkg {
    src = sources.linux-jhovold;
    version = "6.12.0";
    defconfig = "johan_defconfig";
  };

  # Base firmware for the device from mainline `linux-firmware`.
  device-firmware = pkgs.runCommand "device-firmware" {} ''
    mkdir -pv "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX"
    yes | cp -rfv "${linux-firmware-git-src}/qcom/sc8280xp/LENOVO/21BX/." "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX"
  '';

  # Extra firmware for video acceleration support (venus) & gpu.
  graphics-firmware = pkgs.runCommand "graphics-firmware" {} ''
    mkdir -pv "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX"
    yes | cp -fv "${ironrobin-git-src}/x13s-firmware/qcvss8280.mbn" "$out/lib/firmware/qcom/sc8280xp/LENOVO/21BX"
    yes | cp -fv "${ironrobin-git-src}/x13s-firmware/a690_gmu.bin" "$out/lib/firmware/qcom"
  '';

  bluetooth-firmware = pkgs.runCommand "bluetooth-firmware" {} ''
    mkdir -pv "$out/lib/firmware/qca"
    yes | cp -fv "${linux-firmware-git-src}/qca/hpnv21.b8c" "$out/lib/firmware/qca"
    yes | cp -fv "${linux-firmware-git-src}/qca/hpnv21g.b8c" "$out/lib/firmware/qca"
  '';
}
