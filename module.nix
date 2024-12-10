{dtbName}: {
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  cfg = config.nixos-x13s;

  x13sPackages = import ./packages/default.nix {inherit lib pkgs;};

  linuxPackages_x13s = pkgs.linuxPackagesFor (
    if cfg.kernel == "jhovold"
    then x13sPackages.linux_jhovold
    else throw "Unsupported kernel"
  );
  dtb = "${linuxPackages_x13s.kernel}/dtbs/qcom/${dtbName}";
  dtbEfiPath = "dtbs/x13s.dtb";

  modulesClosure = pkgs.makeModulesClosure {
    rootModules = config.boot.initrd.availableKernelModules ++ config.boot.initrd.kernelModules;
    kernel = config.system.modulesTree;
    firmware = config.hardware.firmware;
    allowMissing = false;
  };

  modulesWithExtra = pkgs.symlinkJoin {
    name = "modules-closure";
    paths = [
      modulesClosure
      x13sPackages.device-firmware
      x13sPackages.graphics-firmware
      x13sPackages.bluetooth-firmware
    ];
  };
in {
  options.nixos-x13s = {
    enable = lib.mkEnableOption "x13s hardware support";

    bluetoothMac = lib.mkOption {
      type = lib.types.str;
      description = "Bluetooth MAC address to set on boot";
    };

    kernel = lib.mkOption {
      type = lib.types.enum [
        "jhovold"
      ];
      description = "Which patched kernel to use. jhovold is the latest RC or release with some x13s specific patches.";
      default = "jhovold";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.efibootmgr];

    hardware.enableAllFirmware = true;
    hardware.firmware = lib.mkBefore [
      x13sPackages.device-firmware
      x13sPackages.graphics-firmware
      x13sPackages.bluetooth-firmware
    ];

    boot = {
      initrd.systemd.enable = true;
      initrd.systemd.contents = {
        "/lib".source = lib.mkForce "${modulesWithExtra}/lib";
      };

      loader.efi.canTouchEfiVariables = true;
      loader.systemd-boot.enable = lib.mkDefault true;
      loader.systemd-boot.extraFiles = {
        "${dtbEfiPath}" = dtb;
      };

      kernelPackages = linuxPackages_x13s;

      kernelParams = [
        # needed to boot
        "dtb=${dtbEfiPath}"

        # jhovold recommended
        "efi=noruntime"
        "clk_ignore_unused"
        "pd_ignore_unused"
        "arm64.nopauth"
        # "regulator_ignore_unused" # allows for > 30 sec to load msm, at the potential cost of power
      ];

      initrd = {
        kernelModules = [
          "nvme"
          "phy_qcom_qmp_pcie"
          "pcie_qcom"

          "i2c_core"
          "i2c_hid"
          "i2c_hid-of"
          "i2c_qcom-geni"

          "leds_qcom_lpg"
          "pwm_bl"
          "qrtr"
          "pmic_glink_altmode"
          "gpio_sbu_mux"
          "phy_qcom_qmp_combo"
          "gpucc_sc8280xp"
          "dispcc_sc8280xp"
          "phy_qcom_edp"
          "panel_edp"
          "msm"
        ];
      };
    };

    # https://github.com/jhovold/linux/wiki/X13s#modem
    networking.networkmanager.fccUnlockScripts = [
      {
        id = "105b:e0c3";
        path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/105b";
      }
    ];

    nixpkgs.overlays = [
      (_: super: {
        # don't try and use zfs
        zfs = super.zfs.overrideAttrs (_: {
          meta.platforms = [];
        });

        # allow missing modules
        makeModulesClosure = x: super.makeModulesClosure (x // {allowMissing = true;});
      })
    ];

    # default is performance
    powerManagement.cpuFreqGovernor = "ondemand";

    systemd.services.bluetooth-x13s-mac = {
      wantedBy = ["multi-user.target"];
      before = ["bluetooth.service"];
      requiredBy = ["bluetooth.service"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.util-linux}/bin/script -q -c '${pkgs.bluez}/bin/btmgmt --index 0 public-addr ${cfg.bluetoothMac}'";
      };
    };
  };
}
