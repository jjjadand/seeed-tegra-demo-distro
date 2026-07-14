PREFERRED_PROVIDER_virtual/dtb = "seeed-devicetree"
IMAGE_CLASSES:append = " seeed-recomputer-super-tegraflash"

TEGRA_BOARDID ?= "3701"
TEGRA_BOARDSKU ?= "0000"
TEGRA_FLASHVAR_ODMDATA = "gbe-uphy-config-22,nvhs-uphy-config-0,hsio-uphy-config-16,gbe0-enable-10g,hsstp-lane-map-3"
TEGRA_FLASHVAR_PINMUX_CONFIG = "${SEEED_PINMUX_CONFIG}"
TEGRA_FLASHVAR_PMC_CONFIG = "${SEEED_PMC_CONFIG}"
KERNEL_DEVICETREE = "${SEEED_DTB}"

TEGRA_PLUGIN_MANAGER_OVERLAYS = "L4TConfiguration.dtbo tegra234-carveouts.dtbo tegra-optee.dtbo ${SEEED_OVERLAYS}"
TEGRA_FLASHVAR_DCE_OVERLAY = "${SEEED_DCE_OVERLAY}"
