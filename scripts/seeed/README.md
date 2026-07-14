# Seeed carrier board build helpers

These helpers support all Seeed machines in
`layers/meta-seeed/conf/machine`. Select a target with `--machine` or
`MACHINE=...`.

```bash
./scripts/seeed/build.sh machines

export MACHINE=recomputer-industrial-orin-j401
export BUILD_DIR=build-seeed-industrial-j401

./scripts/seeed/prepare-workspace.sh --machine "$MACHINE" --build-dir "$BUILD_DIR"
./scripts/seeed/build.sh metadata
./scripts/seeed/build.sh dtb
./scripts/seeed/build.sh bootfiles
./scripts/seeed/build.sh image
./scripts/seeed/prepare-flash.sh

./scripts/seeed/validate-all-machines.sh
```

The validation script parses all 16 machines and compiles one complete DT set
for each SoC family (`tegra234` and `tegra264`). It does not claim physical
flash or peripheral validation.

Use a separate build directory per machine when switching targets. Do not reuse
an existing build directory for a different `MACHINE`.

The remaining workspace and flash helpers still accept their documented
machine, build, cache, image, and extraction options.
