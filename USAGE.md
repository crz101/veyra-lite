# Veyra Lite 使用指南 — 插帧

两个场景：**本地视频文件补帧** 和 **PS5 串流实时插帧**。UI 是 Qt Quick，视频是原生 D3D12 窗口。

## 通用原则（先看）

1. **先关效果看画面和声音，再逐个开。** 高分辨率 + 多层 NR + 插帧会显著拉高 GPU/显存。
2. `Submitted FPS` 不是物理刷新率，也不是端到端延迟——上游文档自己反复强调这点。
3. 算法来自你放的专有 DLL，不在源码里。插帧效果取决于 runtime 是否齐全、GPU 是否支持。
4. 上游自承有 drift、VRAM 增长、部分硬件未验证等问题。别把"能跑"当成"所有片子都完美"。

## 场景 A：本地视频文件补帧（离线处理）

用于把已有视频补帧后导出成新文件。走 **List 模式**（Node 模式不支持离线导出）。

1. 启动 `veyra_qml_ui.exe`。Home 页选 **Files**，打开你的视频。
2. 顶部切到 **Professional → List**。
3. 在效果顺序条里找到 **Frame generation**，选一个后端和倍率（2x / 3x / 4x）：
   - NVIDIA：DLSS-G 后端（本构建已开 `VEYRA_ENABLE_DLSS_FG`）
   - RTX 40 系可试多帧生成；RTX 30 需额外的 Ampere unlock，本纯净构建默认不含
   - AMD：FSR-FG / AMF FRC（同构建，取决于 runtime）
4. 勾 **Cadence** / **Display sync** 看实际节奏；**Low-queue mode** 可降低延迟；设 **Output cap**。
5. 打开 **Export**：List 模式确认效果 → 添加文件 → 选 MP4/MKV、码率、音轨/字幕轨 → 开始。
   - 导出是离线跑，不录预览窗口
   - 可暂停/取消/重试，支持分段续跑
   - 注意：不是所有后端都支持离线 FG，按导出界面接受的设置来

> 导出硬件要求低于实时预览（不需要考虑显示同步），但显存占用仍高。长片建议分段。

## 场景 B：PS5 串流实时插帧

走 **Remote Play**（本构建已开 `VEYRA_ENABLE_REMOTEPLAY`，用固定 pin 的 Chiaki 源）。

首次配置：

1. PS5 上开启 **Remote Play**（设置 → 系统 → 远程游玩）。
2. Home 页选 **PS5**，让 Veyra 发现主机或手动填主机 IP。
3. 点 **Get Account ID** → 打开 PSNTools → 把数字或 Base64 Account ID 复制回 Veyra。
4. 输入 PS5 上显示的 8 位配对码。保存后下次直连。
5. 连上后，Professional → List 里按场景 A 第 3–4 步开 Frame generation。

控制（手柄直通）：

- PS5 手柄通过 Chiaki 转发，DualSense 自适应扳机、灯条颜色、玩家指示灯会同步
- 需要采集卡画面 + PS5 手柄控制时，先配对主机，第三方推流软件可中继画面并转发输入
- 手柄相关 bug（L2/R2 卡住）上游已有修复，但真机长时测试仍需你自己验

画质/延迟提示：

- PS5 输出 PQ/HLG 要和采集/显示设置匹配；SDR 与 HDR 是两条不同的处理路径
- 上游有 PS5 SDR 亮度修复（BT.1886/sRGB），但"真实 PS5 同场景尚未复测"——需要你实测确认
- 插帧会引入处理延迟；竞技类游戏自己权衡开不开

## 场景 C：采集卡 / 屏幕画面插帧（顺带可用）

本构建保留了这两个源，不额外收费：

- **采集卡**：选设备、分辨率、帧率、像素格式和音频输入；Magewell Pro Capture 有低延迟选项
- **屏幕**：选窗口/显示器；Game 模式用无边框窗口或显示器，避免递归捕获 Veyra 自己
  - `Home` 开调整，`Home/Esc` 关，`Ctrl+Alt+Home` 退出直通

采集卡插帧要点：先选像素格式和色彩（PQ/HLG/709、Limited/Full），再按信号设 60 帧采集、去重、FG、超分。上游内置"如何选择采集格式"指南。

### 已确认设备：绿联 UG701（P/N 45646）

高端卡，USB-C / USB 3.2 Gen 1（5Gbps），不是 USB2.0 那种 1080p30 的入门卡。

- 采集上限：4K60、1440p144、1080p240
- 格式：YUY2 / NV12 / I420 / RGB24 / MJPEG / **P010（10bit HDR）**
- HDMI 2.1，支持 HDR / VRR；8K60 是**环出**能力，不是采集
- HDCP 不支持 → 接 PS5 必须在系统设置里关 HDCP,否则黑屏

**PS5 插帧 SDR 档（推荐先用这个）**：

1. PS5 输出设 1080p / 60Hz / SDR
2. Veyra 采集：1920×1080 @ 60fps，格式 **MJPEG** 或 **P010**
3. 色彩 BT.709 / Limited,和 PS5 输出对齐
4. List 模式开 Frame generation 2X → 120fps(要 120Hz 显示器才看得出差别)
5. 后端选 DLSS-G(本构建已开)

**HDR 档**：PS5 输出 HDR → 采集格式选 P010 → 色彩 PQ / BT.2020。上游有 PS5 SDR 亮度修复和 HDR 曲线处理，但 release 明确写"真实 PS5 同场景尚未复测",需自己校。

注意：
- 5Gbps 下 4K60+P010 数据量大，先跑 1080p60 稳了再上
- 1080p240 是卡的能力，PS5 输出上限 120,别设 240 白费
- USB-C 必须插主板 USB 3.2 Gen1+ 口,插 USB2.0 口会掉到 1080p30
- 环出是给你玩的时候看的另一路;插帧后画面在 Veyra 窗口 / OBS 里

## 效果栈顺序（List 模式）

```
源 → [可选 SR 超分] → [可选 NR 降噪，最多 4 层] → 颜色 → Frame generation → 输出
```

FG 永远在效果之后。HUD/字幕区域可以用全局 NR 保护排除降噪，但那对 FG 无效。

## 已知不进本构建的

- Moonlight / Sunshine PC 串流（`-WithAllStreaming` 可开）
- Xbox 串流（同上）
- Feature18 神经渲染 NR（`-WithExperimentalNr` 可开，但需 DLSS SDK，不属于插帧）
- 字幕实时翻译（运行时设置里有，但本用途不需要；默认本地模型不外发数据）
- Dolby Vision、去隔行
