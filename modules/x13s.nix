{
  config,
  lib,
  pkgs,
  ...
}: let
  device = (import ../devices.nix).lenovo-thinkpad-x13s;
  cfg = config.hardware.lenovo-thinkpad-x13s;
in {
  options.hardware.lenovo-thinkpad-x13s.enable = lib.mkEnableOption "support for the ${device.displayName}";

  config = lib.mkIf cfg.enable {
    # Although the device has a TPM, there's no driver for it yet and
    # waiting for it will cause a delay at boot, so disable it for now.
    systemd.tpm2.enable = false;

    boot = {
      blacklistedKernelModules = [
        "qcom_iris"
      ];

      initrd.includeDefaultModules = false;
      initrd.systemd.tpm2.enable = false;
      initrd.availableKernelModules = [
        # USB
        "dwc3_qcom"
        "dwc3"
        "extcon_core"
        "phy_qcom_eusb2_repeater"
        "phy_qcom_qmp_combo"
        "phy_qcom_qmp_usb"
        "phy_qcom_snps_femto_v2"
        "phy_snps_eusb2"
        "usb_storage"

        "i2c_hid_of"
        "i2c_qcom_geni"
        "msm"
        "nvme"
        "panel_edp"
        "phy_qcom_edp"
        "phy_qcom_qmp_pcie"
        "qrtr"

        # DP altmode
        "pmic_glink_altmode"

        # PWM, backlight
        "leds_qcom_lpg"
        "pwm_bl"

        # USB-C
        "gpio_sbu_mux"

        # Display
        "gpucc_sc8280xp"
        "dispcc_sc8280xp"

        # Load remoteproc modules in the initramfs. If they are loaded later,
        # it can cause a power cycle that breaks USB.
        "qcom_common"
        "qcom_q6v5_pas"
        "qrtr-smd"

        # Device mapper modules
        "dm_mod"
        "dm_crypt"
      ];

      kernelParams = [
        "pd_ignore_unused"
        "clk_ignore_unused"
        "arm64.nopauth"
      ];

      kernelPackages = pkgs.x13s-linux;
    };

    hardware = {
      deviceTree.enable = true;
      deviceTree.name = lib.mkDefault device.deviceTreeName;
      enableRedistributableFirmware = lib.mkDefault true;
    };

    boot.initrd.extraFirmwarePaths = [
      # Bluetooth
      "qca/hpbtfw21.tlv"
      "qca/hpnv21.b8c"

      # GPU
      "qcom/a660_gmu.bin"
      "qcom/a660_sqe.fw"

      # HW Video Decoding
      "qcom/sc8280xp/LENOVO/21BX/qcvss8280.mbn"

      # remoteproc
      "qcom/sc8280xp/LENOVO/21BX/adspr.jsn"
      "qcom/sc8280xp/LENOVO/21BX/adspua.jsn"
      "qcom/sc8280xp/LENOVO/21BX/audioreach-tplg.bin"
      "qcom/sc8280xp/LENOVO/21BX/battmgr.jsn"
      "qcom/sc8280xp/LENOVO/21BX/cdspr.jsn"
      "qcom/sc8280xp/LENOVO/21BX/qcadsp8280.mbn"
      "qcom/sc8280xp/LENOVO/21BX/qccdsp8280.mbn"
      "qcom/sc8280xp/LENOVO/21BX/qcdxkmsuc8280.mbn"
      "qcom/sc8280xp/LENOVO/21BX/qcslpi8280.mbn"

      # Wi-Fi
      "ath11k/WCN6855/hw2.1/amss.bin"
      "ath11k/WCN6855/hw2.1/board-2.bin"
      "ath11k/WCN6855/hw2.1/m3.bin"
      "ath11k/WCN6855/hw2.1/regdb.bin"
    ];
  };
}
