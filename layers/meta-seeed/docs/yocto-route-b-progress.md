# Seeed Jetson Yocto 路线 B 当前进度

更新时间：2026-07-21

本文记录路线 B 的实际完成状态和验证证据。设计目标与完整验收标准见
[`yocto-route-b-build-plan.md`](yocto-route-b-build-plan.md)。本文只记录已经执行并
确认的结果，不把 metadata 解析、构建成功或历史镜像启动等同于当前新镜像已完成
实机验证。

## 1. 当前结论

- 路线 B 第一阶段 recipe 已合入：runtime、containers、development、tests
  packagegroups，以及 runtime/development 两个 image。
- `recomputer-orin-super-j401` + Jetson Orin NX 16GB 模组 SKU `0000`
  的 `seeed-image-jetson-development` 已完成完整 BitBake 构建。
- development rootfs 已确认包含目标端 CUDA Toolkit、`nvcc`、CUDA/cuDNN/
  TensorRT/VPI/OpenCV 开发文件、编译工具、samples 和 tests。
- ext4、manifest、SPDX SBOM、testdata 和 tegraflash archive 均已成功生成。
- PC 端交叉 SDK 是可选产物，当前尚未完成最终 installer 构建与示例交叉编译验证。
- 当前 development image 尚未记录实机刷写、启动和板端 CUDA smoke test 结果。

## 2. 已完成实现

### 2.1 Image 和 packagegroup

- `seeed-image-jetson-runtime`
- `seeed-image-jetson-development`
- `packagegroup-seeed-jetson-runtime`
- `packagegroup-seeed-jetson-containers`
- `packagegroup-seeed-jetson-development`
- `packagegroup-seeed-jetson-tests`

runtime image 与 NVIDIA/OE4T `demo-image-full` 的 runtime、samples 和 tests
选择对齐，但不安装目标端完整编译工具链。development image 在此基础上增加
板端开发工具链和 NVIDIA/OpenCV 开发文件。

### 2.2 已解决问题

development rootfs 最初在 DNF transaction test 阶段失败：

```text
file /usr/bin/cpp conflicts between attempted installs of
cpp-symlinks and opencv-apps
```

原因是 `opencv-apps` 把 OpenCV C++ 示例安装为 `/usr/bin/cpp/` 目录，而 GCC
需要把 `/usr/bin/cpp` 安装为 C 预处理器符号链接。当前通过
`recipes-support/opencv/opencv_%.bbappend` 将 OpenCV 示例目录改为
`/usr/bin/opencv_cpp/`，同时保留 GCC `cpp` 和全部 OpenCV 示例。

构建脚本也已补充产物打印：成功执行 `image` 或 `flash-package` 后会列出 ext4、
manifest、SBOM、testdata 和 tegraflash archive；`sdk` 会列出 SDK 输出目录和
installer。

## 3. 本次构建记录

### 3.1 构建目标

| 项目 | 值 |
| --- | --- |
| 日期 | 2026-07-21 |
| `MACHINE` | `recomputer-orin-super-j401` |
| 模组 | Jetson Orin NX 16GB，P3767 SKU `0000` |
| Build directory | `build-seeed-super-j401-sku0000` |
| Image | `seeed-image-jetson-development` |
| Distro | `tegrademo` |
| Jetson Linux BSP | `39.2.0` |

执行命令：

```bash
./scripts/seeed/build.sh image \
  --build-dir build-seeed-super-j401-sku0000 \
  --machine recomputer-orin-super-j401 \
  --image seeed-image-jetson-development
```

最终结果：

```text
Tasks Summary: Attempted 13864 tasks of which 13802 didn't need to be rerun
and all succeeded.
```

完成后的缓存复跑为 100% sstate 命中，全部 13864 个任务无需重新执行并成功结束。

### 3.2 构建产物

产物目录：

```text
build-seeed-super-j401-sku0000/tmp/deploy/images/recomputer-orin-super-j401/
```

| 产物 | 大小/说明 |
| --- | --- |
| `seeed-image-jetson-development-recomputer-orin-super-j401.rootfs.ext4` | 29,527,900,160 bytes logical size |
| `seeed-image-jetson-development-recomputer-orin-super-j401.rootfs.manifest` | 100,628 bytes |
| `seeed-image-jetson-development-recomputer-orin-super-j401.rootfs.spdx.json` | 48,746,407 bytes |
| `seeed-image-jetson-development-recomputer-orin-super-j401.rootfs.testdata.json` | 506,182 bytes |
| `seeed-image-jetson-development-recomputer-orin-super-j401.rootfs.tegraflash-tar.zst` | 4,022,945,717 bytes |

tegraflash archive SHA-256：

```text
1d555e280aa31d4d45e509d00e3259ebe3b4235450190c2a1aa9556f2a3bf947
```

这些文件是本地构建产物，不提交到 Git。

## 4. Rootfs 静态验证

已直接检查生成的 ext4 文件系统：

| 检查项 | 结果 |
| --- | --- |
| `/usr/bin/cpp` | 存在，指向 `aarch64-oe4t-linux-cpp` |
| `/usr/bin/opencv_cpp/` | 存在，保存 OpenCV C++ 示例 |
| `/usr/local/cuda-13.2/bin/nvcc` | 存在 |
| `/usr/local/cuda-13.2/include/cuda.h` | 存在 |
| `/usr/include/cudnn.h` | 存在，指向 cuDNN 9 header |
| `/usr/include/NvInfer.h` | 存在 |
| `/opt/nvidia/vpi4/include/vpi/VPI.h` | 存在 |

manifest 已确认包含：

- `cuda-toolkit`、`cuda-nvcc` 及 CUDA development packages；
- `cudnn-dev`；
- TensorRT `libnvinfer-dev`、plugins 和 `trtexec` development packages；
- `libnvvpi4-dev`；
- `opencv-dev`、拆分后的 OpenCV module development packages 和
  `opencv-apps`；
- GCC/G++、CMake、Ninja、pkg-config、Git、GDB 和 Python development packages。

## 5. Git 进度

已推送的相关提交：

| Commit | 内容 |
| --- | --- |
| `e74d1fa` | 实现路线 B runtime/development images 和 packagegroups |
| `735dea7` | 解决 OpenCV `/usr/bin/cpp` 与 GCC 的 rootfs 冲突，并打印构建产物路径 |
| `0532b5a` | 明确 PC 端交叉 SDK 为 Optional |

## 6. 尚未完成

- [ ] 构建并验证 `seeed-image-jetson-runtime` 最终产物。
- [x] 构建 `recomputer-orin-super-j401` SKU `0000` development image。
- [ ] 将当前 development tegraflash archive 刷入 Super J401 并记录启动结果。
- [ ] 在板端运行最小 CUDA、TensorRT、VPI、OpenCV 和 multimedia smoke tests。
- [ ] 可选：生成 PC 端交叉 SDK installer，并交叉编译 CUDA/TensorRT 示例。
- [ ] 在 AGX Orin machine 上构建路线 B image。
- [ ] 在 Thor machine 上构建路线 B image。
- [ ] 对全部 16 个 Seeed machine 执行 metadata/构建矩阵。
- [ ] 建立逐 machine release manifest、checksums 和完整性报告。

## 7. 下一步建议

优先使用本次生成的 development tegraflash archive 在 Super J401 SKU `0000`
上完成刷写和启动验证。启动后至少检查：

```bash
nvcc --version
test -f /usr/local/cuda-13.2/include/cuda.h
test -f /usr/include/cudnn.h
test -f /usr/include/NvInfer.h
test -f /opt/nvidia/vpi4/include/vpi/VPI.h
```

随后编译运行最小 CUDA 程序，再继续 TensorRT、VPI、OpenCV、Docker/NVIDIA
Container Toolkit 和载板外设测试。只有需要 PC 端交叉编译时，才执行可选的：

```bash
./scripts/seeed/build.sh sdk \
  --build-dir build-seeed-super-j401-sku0000 \
  --machine recomputer-orin-super-j401 \
  --image seeed-image-jetson-development
```
