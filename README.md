# nixos-x13s

This repository provides NixOS support for the Lenovo ThinkPad X13s.

## Flake usage

Add this repository as an input:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    x13s-nixos = {
      url = "github:gian-reto/x13s-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

Then use the exported module in your configuration:

```nix
{
  outputs = { nixpkgs, x13s-nixos, ... }: {
    nixosConfigurations.x13s = nixpkgs.lib.nixosSystem {
      modules = [
        x13s-nixos.nixosModules.default
        {
          nixpkgs.hostPlatform = "aarch64-linux";
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
  };
}
```

## Installer ISO

This repository exposes an X13s installer ISO as `.#iso` on `aarch64-linux`. Additionally, tagged releases also publish the pre-built ISO and `SHA256SUMS` as GitHub release assets.

Build it with:

```bash
nix build .#iso
```

The built ISO is available under `result/iso/`.

### Cross-compiling from x86_64

Cross-compilation from `x86_64-linux` to `aarch64-linux` is also supported.

Build the installer ISO locally on an `x86_64-linux` machine with:

```bash
nix build .#packages.x86_64-linux.iso --no-write-lock-file --show-trace
```

Note: Cross-compiling can take a long time (potentially multiple hours), as many packages need to be built from source.

### Flashing the ISO to an USB drive

Flash it to a USB drive with:

```bash
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M conv=fsync status=progress
sync
```

Replace `/dev/sdX` with your USB device.

## Firmware updates

The repository exposes the extracted Lenovo firmware update package as `.#uefi`. Previously, this flake provided a way to build an ISO for updating the firmware. However, this doesn't seem to work anymore, see: https://gitlab.com/TheOneWithTheBraid/x13s-firmware-update/-/work_items/1. Therefore, it is recommended to update the device firmware as described below.

### Installing a firmware update with `fwupdtool`

Make sure that `fwupd` is enabled in your NixOS system configuration:

```nix
services.fwupd.enable = true;
```

Clone this repository and obtain the firmware by building the `.#uefi` package:

```bash
nix build .#uefi
```

This produces the extracted Lenovo updater files under `result/`, including the firmware capsule payload in `result/Flash/`.

Find the `System Firmware` device ID using `fwupdmgr get-devices`, and install the capsule blob from the extracted package:

```bash
sudo fwupdtool install-blob result/Flash/*/'$0AN3H00.FL1' <device-id>
reboot
```

Replace `<device-id>` with the `Device ID` reported for `System Firmware`.

`fwupdtool` stages the update onto the internal EFI system partition and the firmware applies it during the next reboot.

## Development notes

### Updating the Lenovo UEFI update package

The UEFI update package metadata lives in `packages/uefi.nix`.

When Lenovo publishes a new update, refresh these values:

- `version`
- `src.url`
- `src.hash`

To discover the latest BIOS update download URL, you can use the Lenovo support API:

```bash
curl --silent --fail \
  --header 'User-Agent: Mozilla/5.0' \
  --header 'Referer: https://pcsupport.lenovo.com/' \
  'https://pcsupport.lenovo.com/us/en/api/v4/downloads/drivers?productId=21BX' \
| jq -r '.body.DownloadItems[] | select(.Title | contains("BIOS Update")) | .Files[] | select(.TypeString == "EXE") | .URL'
```

Once you have the new URL, prefetch it to get the fixed-output hash and then update `packages/uefi.nix`.

One easy workflow is:

1. Prefetch the file:

   ```bash
   nix store prefetch-file --json '<n3huj20w.exe-download-url>'
   ```

2. Copy the reported `hash` into `packages/uefi.nix`
3. Update `version` and `url` in `packages/uefi.nix`
4. Rebuild the extracted firmware package and verify the output in `result/`:

   ```bash
   nix build .#uefi
   ```

Note: If you use [`nurl`](https://github.com/nix-community/nurl), you can generate the `fetchurl` snippet directly:

```bash
nurl <n3huj20w.exe-download-url> -f fetchurl
```

Example output:

```nix
fetchurl {
  url = "<n3huj20w.exe-download-url>";
  hash = "sha256-A3l/ZfIbFcvFX+bMWYgpW+1kkYPu5MQkuTCgszhaoIY=";
}
```

## Releasing

Tagged releases publish the pre-built installer ISO and `SHA256SUMS` as GitHub release assets.

1. Update `main` with the changes you want to release.
2. Create an annotated tag matching `v*`:

   ```bash
   git checkout main
   git pull --ff-only
   git tag -a v2026.04.03-1 -m "Release v2026.04.03-1"
   ```

3. Push the tag:

   ```bash
   git push origin v2026.04.03-1
   ```

4. Wait for the `Release` GitHub Actions workflow to finish.
5. Verify that the GitHub Release contains the ISO and `SHA256SUMS`.

# Thanks

- The original version of this was forked from [nixos-x13s](https://codeberg.org/adamcstephens/nixos-x13s) by Adam Stephens. Thanks, Adam!
- The refactoring is heavily inspired by [x1e-nixos-config](https://github.com/kuruczgy/x1e-nixos-config), especially https://github.com/kuruczgy/x1e-nixos-config/pull/198. Thanks [kuruczgy](https://github.com/kuruczgy) and [phodina](https://github.com/phodina)!
