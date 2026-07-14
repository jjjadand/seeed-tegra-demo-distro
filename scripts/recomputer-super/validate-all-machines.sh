#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
BUILD_DIR=${BUILD_DIR:-build-seeed-validation}

mapfile -t machines < <(
    find "$REPO_ROOT/layers/meta-seeed/conf/machine" -maxdepth 1 -name '*.conf' \
        -printf '%f\n' | sed 's/\.conf$//' | sort
)

cd "$REPO_ROOT"
set +u
. ./setup-env --machine "${machines[0]}" "$BUILD_DIR"
set -u

for machine in "${machines[@]}"; do
    echo "==> Parsing $machine"
    BB_ENV_PASSTHROUGH_ADDITIONS=MACHINE MACHINE="$machine" \
        bitbake -e seeed-devicetree >/dev/null
done

for machine in recomputer-orin-super-j401 recomputer-thor-carrier-j601; do
    echo "==> Compiling the ${machine} device-tree family"
    BB_ENV_PASSTHROUGH_ADDITIONS=MACHINE MACHINE="$machine" \
        bitbake -c compile seeed-devicetree
done

echo "Validated ${#machines[@]} Seeed machines. Hardware validation is separate."
