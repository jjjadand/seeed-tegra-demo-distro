PREFERRED_PROVIDER_virtual/dtb = "seeed-devicetree"
IMAGE_CLASSES:append = " seeed-recomputer-super-tegraflash"

TEGRA_BOARDID ?= "3701"
SEEED_MODULE_SKU ?= "${SEEED_DEFAULT_MODULE_SKU}"
SEEED_MODULE_DTB_SKU_MAP ?= "0000:0000 0001:0000 0002:0000 0004:0004 0005:0005"
SEEED_MODULE_BPMP_SKU_MAP ?= "${SEEED_MODULE_DTB_SKU_MAP}"

def seeed_module_sku_map(d, mapvar):
    entries = (d.getVar(mapvar) or "").split()
    mapping = dict(entry.split(":", 1) for entry in entries)
    return mapping.get(d.getVar("SEEED_MODULE_SKU"), "")

SEEED_MODULE_DTB_SKU = "${@seeed_module_sku_map(d, 'SEEED_MODULE_DTB_SKU_MAP')}"
SEEED_MODULE_BPMP_SKU = "${@seeed_module_sku_map(d, 'SEEED_MODULE_BPMP_SKU_MAP')}"

python () {
    sku = d.getVar("SEEED_MODULE_SKU")
    supported = (d.getVar("SEEED_SUPPORTED_MODULE_SKUS") or "").split()
    if not sku:
        bb.fatal("SEEED_MODULE_SKU is not configured for %s" % d.getVar("MACHINE"))
    if sku not in supported:
        bb.fatal("Unsupported SEEED_MODULE_SKU %s for %s; supported values: %s" %
                 (sku, d.getVar("MACHINE"), " ".join(supported)))
    if not d.getVar("SEEED_MODULE_DTB_SKU") or not d.getVar("SEEED_MODULE_BPMP_SKU"):
        bb.fatal("Missing DTB/BPMP mapping for SEEED_MODULE_SKU %s" % sku)
}

TEGRA_BOARDSKU = "${SEEED_MODULE_SKU}"
TEGRA_FLASHVAR_BPFDTB_FILE = "tegra234-bpmp-3701-${SEEED_MODULE_BPMP_SKU}-3737-0000.dtb"
TEGRA_FLASHVAR_ODMDATA = "gbe-uphy-config-22,nvhs-uphy-config-0,hsio-uphy-config-16,gbe0-enable-10g,hsstp-lane-map-3"
TEGRA_FLASHVAR_PINMUX_CONFIG = "${SEEED_PINMUX_CONFIG}"
TEGRA_FLASHVAR_PMC_CONFIG = "${SEEED_PMC_CONFIG}"
KERNEL_DEVICETREE = "${SEEED_DTB}"

TEGRA_PLUGIN_MANAGER_OVERLAYS = "L4TConfiguration.dtbo tegra234-carveouts.dtbo tegra-optee.dtbo ${SEEED_OVERLAYS}"
TEGRA_FLASHVAR_DCE_OVERLAY = "${SEEED_DCE_OVERLAY}"
