# Veyra Lite 构建指南

## 前置（全部需要你本机自备）

- Windows 11 x64
- Visual Studio 2022（MSVC C++20）
- CMake 3.24+、Ninja
- Python 3.11+
- vcpkg 的 x64-windows FFmpeg（`vcpkg install ffmpeg[x64-windows]`，对应 `VEYRA_FFMPEG_ROOT`）
- **专有 runtime / SDK（仓库不含，必须合法取得）**：
  - NVIDIA DLSS SDK 310.7（只有开 Feature-18 NR 才需要）
  - NVIDIA Optical Flow SDK（光流引导，插帧质量相关；放在 `third_party_local/nvidia/Optical_Flow_SDK_5.0.7/` 可自动识别）
  - Chiaki stage（PS5 Remote Play 用；按 `scripts/remoteplay/patches/0001..0003` 打补丁并跑 verify）
  - `nvidia_dlss` / `nvngx_dlssg.dll` 等运行时 DLL —— 上游固定 hash 的那些文件

> 仓库本身**不含**任何专有二进制。`Source Git excludes proprietary runtimes/models`（上游 README 原话）。没有这些文件，编译能过，插帧跑不起来。

## 一键配置

把 `configure-lite.ps1` 复制到上游仓库根目录，然后（PowerShell）：

```powershell
# 看一眼会执行什么，不实际运行
.\configure-lite.ps1 -DryRun `
  -ChiakiSourceDir "E:\veyra-deps\chiaki-stage" `
  -ChiakiVerifyDir "E:\veyra-deps\chiaki-source" `
  -FfmpegRoot "C:\vcpkg\installed\x64-windows"

# 实际 configure + build
.\configure-lite.ps1 `
  -ChiakiSourceDir "E:\veyra-deps\chiaki-stage" `
  -ChiakiVerifyDir "E:\veyra-deps\chiaki-source" `
  -FfmpegRoot "C:\vcpkg\installed\x64-windows"
```

产物：`out/build/x64-release/` 下的 `veyra_qml_ui.exe`。

## 手动等价命令

```powershell
cmake --preset x64-release `
  -DVEYRA_ENABLE_DLSS_FG=ON `
  -DVEYRA_ENABLE_NVOF=ON `
  -DVEYRA_ENABLE_REMOTEPLAY=ON `
  -DVEYRA_ENABLE_DLSS_SR=ON `
  -DVEYRA_ENABLE_MOONLIGHT=OFF `
  -DVEYRA_ENABLE_XBOX=OFF `
  -DVEYRA_ENABLE_LIBDOVI=OFF `
  -DVEYRA_ENABLE_DEINTERLACE=OFF `
  -DVEYRA_ENABLE_EXPERIMENTAL_DLSSNR=OFF `
  -DVEYRA_ENABLE_D3D12_DEBUG=OFF `
  -DVEYRA_RP_CHIAKI_SOURCE_DIR="..." `
  -DVEYRA_RP_CHIAKI_VERIFY_DIR="..." `
  -DVEYRA_FFMPEG_ROOT="..."
cmake --build --preset x64-release --target veyra_qml_ui
```

## 关键 flag 说明

| Flag | 本构建 | 作用 |
|---|---|---|
| `VEYRA_ENABLE_DLSS_FG` | ON | DLSS-G 帧生成后端（插帧核心） |
| `VEYRA_ENABLE_NVOF` | ON | NVIDIA 光流，给插帧提供运动引导 |
| `VEYRA_ENABLE_REMOTEPLAY` | ON | PS5 Remote Play 画面源 |
| `VEYRA_ENABLE_DLSS_SR` | ON | 超分，常与插帧搭配 |
| `VEYRA_ENABLE_EXPERIMENTAL_DLSSNR` | OFF | Feature18 神经渲染，不是插帧必需，且需 DLSS SDK |
| `VEYRA_ENABLE_MOONLIGHT` / `XBOX` | OFF | 非 PS5 的串流后端 |
| `VEYRA_ENABLE_LIBDOVI` | OFF | Dolby Vision，精简掉 |
| `VEYRA_ENABLE_DEINTERLACE` | OFF | 隔行扫描去隔行，精简掉 |
| `VEYRA_ENABLE_D3D12_DEBUG` | OFF | release 关闭调试层 |

需要 MXFG（多帧生成）时，上游有 `tools/dlssg_ampere_probe` / `tools/dlssg_unlock_probe` 诊断目标，但那属于实验性 unlock，不在本纯净构建的默认路径里。

## 常见坑

- **`VEYRA_ENABLE_EXPERIMENTAL_DLSSNR=ON` 但没有 `VEYRA_DLSS_SDK_ROOT`** → configure 直接 FATAL_ERROR。纯净构建默认关它，别乱开。
- **Chiaki stage 没打补丁** → CMake 的 PS5 后端会找不到固定 source/verify 目录。按 `scripts/remoteplay/patches/` 顺序打 `0001..0004`，跑 `verify-chiaki-stage.py`。
- **缺 FFmpeg** → vcpkg 装 x64-windows 版并指 `VEYRA_FFMPEG_ROOT`。
- **Ninja + MSVC 头文件依赖探测失败** → CMake 会主动探测 `/showIncludes` 前缀，一般不用管；手动改 generator 容易踩坑。
- **改了 flag 但没重建** → configure 缓存了旧值，加 `--fresh` 或删 `out/build/x64-release/CMakeCache.txt` 重来。

## 未验证声明

我这边**没有编译环境**（无 MSVC / 无专有 SDK / 无完整源码，本地 clone 因 TLS 故障失败），以上配置和命令基于上游 `CMakeLists.txt`、`CMakePresets.json`、`docs/DEVELOPMENT.md` 的实际内容整理，**未经实机编译验证**。第一次构建请把完整日志留下来，报什么错直接发我，我按错误信息定点修。
