#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)

BUILD_DIR=${BUILD_DIR:-}
EXPECTED_MACHINE=${MACHINE:-}
IMAGE=${IMAGE:-demo-image-full}
OUTPUT_DIR=${OUTPUT_DIR:-}
ARCHIVE=

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Verify and extract a Seeed machine tegraflash package into a clean, separate
directory. This script does not run sudo or flash the target.

Options:
  --archive FILE    Explicit .tegraflash-tar.zst archive
  --output-dir DIR  Extraction directory (default: ~/seeed-flash-MACHINE)
  --build-dir DIR   Temporarily use this prepared build directory
  --machine NAME    Verify that the prepared build uses this MACHINE
  --image NAME      Image name (default: $IMAGE)
  -h, --help        Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --archive)
            ARCHIVE=$2
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR=$2
            shift 2
            ;;
        --build-dir)
            BUILD_DIR=$2
            shift 2
            ;;
        --machine)
            EXPECTED_MACHINE=$2
            shift 2
            ;;
        --image)
            IMAGE=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ -z $BUILD_DIR ]]; then
    active_file=$(git -C "$REPO_ROOT" rev-parse --git-path seeed-active-build)
    if [[ $active_file != /* ]]; then
        active_file="$REPO_ROOT/$active_file"
    fi
    if [[ -s $active_file ]]; then
        BUILD_DIR=$(<"$active_file")
    else
        BUILD_DIR=build-seeed
    fi
fi

if [[ $BUILD_DIR != /* ]]; then
    BUILD_DIR="$REPO_ROOT/$BUILD_DIR"
fi
BUILD_DIR=$(readlink -m "$BUILD_DIR")

local_conf="$BUILD_DIR/conf/local.conf"
if [[ ! -f $local_conf ]]; then
    echo "ERROR: $BUILD_DIR is not a prepared Yocto build directory." >&2
    exit 1
fi

MACHINE=$(awk -F'"' \
    '/^[[:space:]]*MACHINE[[:space:]]*(\?|\+|:)?=/{print $2; exit}' \
    "$local_conf")
if [[ -z $MACHINE ]]; then
    echo "ERROR: cannot determine MACHINE from $local_conf" >&2
    exit 1
fi
if [[ -n $EXPECTED_MACHINE && $EXPECTED_MACHINE != "$MACHINE" ]]; then
    echo "ERROR: build directory is configured for $MACHINE, not $EXPECTED_MACHINE" >&2
    exit 1
fi

MODULE_SKU=$(sed -n \
    's/^[[:space:]]*SEEED_MODULE_SKU[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$BUILD_DIR/conf/seeed-machine.conf" 2>/dev/null | head -n 1)

OUTPUT_DIR=${OUTPUT_DIR:-$HOME/seeed-flash-$MACHINE}

if [[ -z $ARCHIVE ]]; then
    ARCHIVE="$BUILD_DIR/tmp/deploy/images/$MACHINE/$IMAGE-$MACHINE.rootfs.tegraflash-tar.zst"
fi

if [[ ! -e $ARCHIVE ]]; then
    echo "ERROR: flash archive not found: $ARCHIVE" >&2
    exit 1
fi

ARCHIVE=$(readlink -f "$ARCHIVE")
OUTPUT_DIR=$(readlink -m "$OUTPUT_DIR")

if mount_source=$(findmnt -n -T "$OUTPUT_DIR" -o SOURCE 2>/dev/null); then
    case "$mount_source" in
        /dev/sd*|/dev/disk/by-*|/dev/mapper/*)
            echo "NOTE: extraction target is on $mount_source. A host-local SSD is recommended." >&2
            ;;
    esac
fi

if [[ -e $OUTPUT_DIR && -n $(find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null) ]]; then
    echo "ERROR: output directory is not empty: $OUTPUT_DIR" >&2
    echo "Use a new directory or remove the old extraction manually." >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
echo "==> Extracting $ARCHIVE"
tar xf "$ARCHIVE" -C "$OUTPUT_DIR"

required_files=(
    initrd-flash
    flashvars
    .env.initrd-flash
    "$IMAGE.ext4"
)

for variable in DTB_FILE BPFDTB_FILE PINMUX_CONFIG PMC_CONFIG; do
    value=$(sed -n "s/^${variable}=\"\{0,1\}\([^\"]*\)\"\{0,1\}$/\1/p" \
        "$OUTPUT_DIR/flashvars" | tail -1)
    if [[ -n $value && $value != *@* ]]; then
        required_files+=("$value")
    fi
done

for file in "${required_files[@]}"; do
    if [[ ! -s "$OUTPUT_DIR/$file" ]]; then
        echo "ERROR: required flash-package file missing or empty: $file" >&2
        exit 1
    fi
    echo "OK: $file"
done

archive_module_sku=$(sed -n \
    's/^DEFAULTS\[BOARDSKU\]="\([^"]*\)"$/\1/p' \
    "$OUTPUT_DIR/.env.initrd-flash" | tail -1)
if [[ -n $MODULE_SKU && $archive_module_sku != "$MODULE_SKU" ]]; then
    echo "ERROR: flash archive module SKU does not match the prepared workspace." >&2
    echo "  Workspace: $MODULE_SKU" >&2
    echo "  Archive:   ${archive_module_sku:-missing}" >&2
    exit 1
fi
if [[ -n $archive_module_sku ]]; then
    echo "OK: module SKU $archive_module_sku"
fi

echo
grep -E '^(DTB_FILE|BPFDTB_FILE|PINMUX_CONFIG|PMC_CONFIG|DCE_OVERLAY|PLUGIN_MANAGER_OVERLAYS|BOOTCONTROL_OVERLAYS)=' \
    "$OUTPUT_DIR/flashvars"
cat "$OUTPUT_DIR/.env.initrd-flash"

cat <<EOF

Flash directory is ready:
  $OUTPUT_DIR

Next steps:
  1. Put the Jetson into Force Recovery Mode.
  2. Confirm it with: lsusb -d 0955:
  3. Run from the prepared directory:

       cd "$OUTPUT_DIR"
       sudo ./initrd-flash

Do not assume the temporary host block device is always /dev/sdb or /dev/sdc.
EOF
