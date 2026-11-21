# Veyra Lite — 插帧专用构建

基于 `Likely7/Veyra-NRVideo` v2.2.0 的**纯净构建配置**：只做本地视频补帧和 PS5 串流实时插帧，去掉代币引流、跨设备串流、字幕翻译和花哨 UI 的构建开关。

## 为什么是"配置"而不是"删代码"

上游是单体 C++ 应用：单个 `veyra_qml_ui.exe` 链接 base/gfx/ngx/pipeline/source/ui 等全部 target，模块之间通过头文件深度耦合。直接删除目录会断裂编译，且以后无法跟随上游更新。

上游已经内建 feature flag，且**默认全部 OFF**。纯净版 = 一组精心选择的 flag + 一份专注插帧的文档，而不是 fork 源码。这样：

- 不破坏编译，跟上游 `git pull` 即可升级
- 不引入我无法验证的代码改动
- 需要的功能（文件源、PS5 Remote Play、DLSS-G 帧生成、光流引导）全部打开
- 不需要的（Moonlight、Xbox、Feature18 NR、Dolby Vision、去隔行）保持关闭

## 这个构建包含什么

| 能力 | 开关 | 状态 |
|---|---|---|
| 本地视频文件补帧 | 内置 `MediaFileSource` | 开 |
| PS5 Remote Play 实时插帧 | `VEYRA_ENABLE_REMOTEPLAY` | 开 |
| DLSS-G 帧生成后端 | `VEYRA_ENABLE_DLSS_FG` | 开 |
| NVIDIA 光流引导 | `VEYRA_ENABLE_NVOF` | 开 |
| 采集卡 / 屏幕画面插帧 | 内置 `CaptureCardSource`/`ScreenCaptureSource` | 开 |
| Moonlight / Sunshine PC 串流 | `VEYRA_ENABLE_MOONLIGHT` | 关 |
| Xbox 串流 | `VEYRA_ENABLE_XBOX` | 关 |
| Feature18 实验性 DLSS-NR | `VEYRA_ENABLE_EXPERIMENTAL_DLSSNR` | 关 |
| Dolby Vision | `VEYRA_ENABLE_LIBDOVI` | 关 |
| 实时字幕翻译 | 运行时设置，默认本地模型 | 可不用 |

## 重要事实（别被宣传误导）

1. **这不是官方 DLSS 5。** 上游自己的施工手册写明 NVIDIA 没有公开通用 DLSS 5 接口；这里用的是固定 hash 的 `nvngx_dlssnr.dll` Feature 18 适配 + IAT patch + 架构 spoof，属于社区 runtime。仓库 README 也承认"非厂商认证、非完整官方集成"。
2. **算法不在源码里。** 帧生成/NR 的实际算法来自你自己放置的 NVIDIA 专有 DLL 和 SDK；本仓库只有调度框架。没有这些文件，构建能过但插帧跑不起来。
3. **上游 README 挂了 Pump.fun 代币合约地址并承认收取 creator fee。** 本纯净版的文档不引用、不宣传任何代币。任何让你买币的说法都与软件质量无关。
4. **上游自承 Phase 5–7 未全过**，有 drift P95 2.8 秒、GBV descriptor 错误等未解项。把 README 的 Highlights 当成已验收事实会踩坑。

## 文件

- `configure-lite.ps1` — 一键 configure，设置所有 flag 和依赖路径
- `BUILD.md` — 前置依赖、构建步骤、常见坑
- `USAGE.md` — 文件补帧 + PS5 插帧的操作步骤

## 来源与许可

- 上游：https://github.com/Likely7/Veyra-NRVideo （GPL-3.0；Chiaki 相关 AGPL-3.0 + OpenSSL exception）
- 本目录只提供配置和文档，不含上游源码、不含任何专有 runtime/SDK/模型
- 使用前请自行审阅上游 `LICENSE` 与 `THIRD_PARTY_NOTICES.md`
