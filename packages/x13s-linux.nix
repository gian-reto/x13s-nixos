{
  b4,
  buildLinux,
  fetchFromGitHub,
  lib,
  linuxPackagesFor,
  ...
}:
linuxPackagesFor (buildLinux {
  src = fetchFromGitHub {
    owner = "torvalds";
    repo = "linux";
    tag = "v6.19";
    forceFetchGit = true;
    nativeBuildInputs = [b4];
    preFetch = "export ${lib.toShellVar "NIX_PREFETCH_GIT_CHECKOUT_HOOK" ''
      pushd "$dir"
      git config user.name "nix"
      git config user.email "nix@example.invalid"

      git fetch 'https://gitlab.com/Linaro/arm64-laptops/linux.git' --depth 106 19e59e1b39ad789a5bf90b0b9850bb11ca9f7ebb
      git cherry-pick --empty=drop 63804fed149a6750ffd28610c5c1c98cce6bd377..19e59e1b39ad789a5bf90b0b9850bb11ca9f7ebb

      popd
    ''}";
    hash = "sha256-qElJ642reD/NX63qEBNDgFFVBWxO0zqQxWXDFHeqJu0=";
  };

  version = "6.19.0";

  ignoreConfigErrors = true;

  structuredExtraConfig = with lib.kernel; {
    VIRTUALIZATION = yes;
    KVM = yes;
    MAGIC_SYSRQ = yes;

    ACPI = no;
    HOTPLUG_PCI = no;

    ARCH_ACTIONS = no;
    ARCH_AIROHA = no;
    ARCH_ALPINE = no;
    ARCH_APPLE = no;
    ARCH_AXIADO = no;
    ARCH_BCM = no;
    ARCH_BCM2835 = no;
    ARCH_BCM_IPROC = no;
    ARCH_BCMBCA = no;
    ARCH_BERLIN = no;
    ARCH_BLAIZE = no;
    ARCH_BRCMSTB = no;
    ARCH_CIX = no;
    ARCH_EXYNOS = no;
    ARCH_HISI = no;
    ARCH_INTEL_SOCFPGA = no;
    ARCH_K3 = no;
    ARCH_KEEMBAY = no;
    ARCH_LAYERSCAPE = no;
    ARCH_LG1K = no;
    ARCH_MA35 = no;
    ARCH_MEDIATEK = no;
    ARCH_MESON = no;
    ARCH_MVEBU = no;
    ARCH_MXC = no;
    ARCH_NPCM = no;
    ARCH_NXP = no;
    ARCH_REALTEK = no;
    ARCH_RENESAS = no;
    ARCH_ROCKCHIP = no;
    ARCH_S32 = no;
    ARCH_SEATTLE = no;
    ARCH_SOPHGO = no;
    ARCH_SPARX5 = no;
    ARCH_SPRD = no;
    ARCH_STM32 = no;
    ARCH_SUNXI = no;
    ARCH_SYNQUACER = no;
    ARCH_TEGRA = no;
    ARCH_TESLA_FSD = no;
    ARCH_THUNDER = no;
    ARCH_THUNDER2 = no;
    ARCH_UNIPHIER = no;
    ARCH_VEXPRESS = no;
    ARCH_VISCONTI = no;
    ARCH_XGENE = no;
    ARCH_ZYNQMP = no;

    DRM_ETNAVIV = no;
    DRM_HISI_HIBMC = no;
    DRM_HISI_KIRIN = no;
    DRM_LIMA = no;
    DRM_NOUVEAU = no;
    DRM_PANFROST = no;
    DRM_PANTHOR = no;
    DRM_POWERVR = no;
    DRM_TIDSS = no;

    WLAN_VENDOR_ADMTEK = no;
    WLAN_VENDOR_ATMEL = no;
    WLAN_VENDOR_BROADCOM = no;
    WLAN_VENDOR_INTEL = no;
    WLAN_VENDOR_INTERSIL = no;
    WLAN_VENDOR_MARVELL = no;
    WLAN_VENDOR_MEDIATEK = no;
    WLAN_VENDOR_MICROCHIP = no;
    WLAN_VENDOR_PURELIFI = no;
    WLAN_VENDOR_QUANTENNA = no;
    WLAN_VENDOR_RALINK = no;
    WLAN_VENDOR_REALTEK = no;
    WLAN_VENDOR_RSI = no;
    WLAN_VENDOR_SILABS = no;
    WLAN_VENDOR_ST = no;
    WLAN_VENDOR_TI = no;
    WLAN_VENDOR_ZYDAS = no;

    SND_DRIVERS = no;
    SND_PCI = no;
  };
})
