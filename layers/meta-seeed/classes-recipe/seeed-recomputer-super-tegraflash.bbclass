SEEED_TEGRAFLASH_FILES = "${@' '.join(sorted(os.listdir(d.getVar('SEEED_LAYERDIR') + '/recipes-bsp/tegra-binaries/tegra-bootfiles')))}"

tegraflash_custom_pre() {
    for bctfile in ${SEEED_TEGRAFLASH_FILES}; do
        [ -f "${STAGING_DATADIR}/tegraflash/$bctfile" ] && cp "${STAGING_DATADIR}/tegraflash/$bctfile" .
    done
}
