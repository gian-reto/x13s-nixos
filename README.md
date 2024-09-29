# nixos x13s

> [!NOTE]
> This project was forked from [adamcstephens/nixos-x13s](https://codeberg.org/adamcstephens/nixos-x13s), which is now unmaintained.

This repository aims to provide easy, shared, support for Lenovo X13s on Linux.

The support for this machine is constantly improving in mainline kernel and upstream packages. Eventually the goal is that this repository is no longer necessary.

## Add with a flake

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-x13s.url = "github:gian-reto/x13s-nixos";
  };

  outputs =
    { ... }@inputs:
    {
      nixosConfigurations.example = inputs.nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          inputs.nixos-x13s.nixosModules.default
          {
            nixos-x13s.enable = true;
            nixos-x13s.kernel = "jhovold"; # `jhovold` is default, but mainline supported.

            # Install multiple kernels! Note this increases eval time for each specialization.
            specialisation = {
              # Note that activation of each specialization is required to copy the dtb to the EFI, and thus boot.
              mainline.configuration.nixos-x13s.kernel = "mainline";
            };

            # Allow unfree firmware.
            nixpkgs.config.allowUnfree = true;

            # Define your fileSystems.
            fileSystems."/".device = "/dev/notreal";
          }
        ];
      };
    };
}
```

## Add using not a flake

Clone the repository:

```
 git clone https://github.com/gian-reto/x13s-nixos.git /etc/nixos/nixos-x13s
```

Then reference the module in your `configuration.nix` and use the module as documented in the flake example above:

```nix
  imports =
    [
      ./nixos-x13s/module.nix
    ];
  nixos-x13s.enable = true;
  ...
```

## UEFI Update ISO

This repository provides a package which can output the USB UEFI Update ISO. This will be updated as Lenovo releases new versions.

```
nix build .#uefi-usbiso

dd if=result/usbdisk-*.iso of=/path/to/usb/disk
```

Reboot, select USB drive from F12 boot menu, follow wizard.
