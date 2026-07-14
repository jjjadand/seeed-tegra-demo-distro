DESCRIPTION = "Seeed carrier board device trees"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

inherit tegra-devicetree

COMPATIBLE_MACHINE = "(recomputer|reserver|seeed-agx-orin-kit)"

S = "${UNPACKDIR}"

# Import the required Seeed-modified platform and overlay DTS dependency closure.
SRC_URI = " \
    ${@' '.join('file://' + f for f in sorted(os.listdir(d.getVar('THISDIR') + '/seeed-devicetree')) if f.endswith('.dts') or f.endswith('.dtsi'))} \
    file://gmsl \
"

DT_FILES:tegra234 = " \
    tegra234-j201-p3768-0000+p3767-0000-recomputer-indu.dtb \
    tegra234-j401-p3768-0000+p3767-0000-recomputer.dtb \
    tegra234-j401-p3768-0000+p3767-0000-recomputer-robo.dtb \
    tegra234-j401-p3768-0000+p3767-0000-recomputer-robo-gmsl.dtb \
    tegra234-j401-p3768-0000+p3767-0000-recomputer-rugged.dtb \
    tegra234-j401-p3768-0000+p3767-0000-recomputer-super.dtb \
    tegra234-j401-p3768-0000+p3767-0000-reserver-indu.dtb \
    tegra234-j40mini-p3768-0000+p3767-0000-recomputer.dtb \
    tegra234-j501x-0000+p3701-0000-recomputer-mini.dtb \
    tegra234-j501x-0000+p3701-0000-recomputer-robo.dtb \
    tegra234-j501x-0000+p3701-0000-reserver-gmsl.dtb \
    tegra234-j501x-0000+p3701-0000-reserver.dtb \
    tegra234-p3737-0000+p3701-0000-seeed.dtb \
    tegra234-p3767-camera-p3768-imx219-quad-seeed.dtbo \
    tegra234-seeed-gmsl-recomputer-robo-3g-overlay.dtbo \
    tegra234-seeed-gmsl-recomputer-robo-6g-overlay.dtbo \
"

DT_FILES:tegra264 = " \
    tegra264-p4071-0000+p3834-0000-recomputer-carrier.dtb \
    tegra264-p4071-0000+p3834-0008-recomputer-carrier.dtb \
"
