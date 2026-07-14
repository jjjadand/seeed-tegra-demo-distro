FILESEXTRAPATHS:prepend := "${THISDIR}/tegra-bootfiles:"

SRC_URI:append = " \
    ${@' '.join('file://' + f for f in sorted(os.listdir(d.getVar('SEEED_LAYERDIR') + '/recipes-bsp/tegra-binaries/tegra-bootfiles')))} \
"

do_install:append() {
    for file in ${SEEED_LAYERDIR}/recipes-bsp/tegra-binaries/tegra-bootfiles/*.dts \
                ${SEEED_LAYERDIR}/recipes-bsp/tegra-binaries/tegra-bootfiles/*.dtsi; do
        [ -f "$file" ] || continue
        install -m 0644 "$file" ${D}${datadir}/tegraflash/
    done
}
