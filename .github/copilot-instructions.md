# Veyra Lite — Copilot project notes

This repository contains a **build configuration and usage docs** for a clean, frame-generation-only variant of `Likely7/Veyra-NRVideo` v2.2.0. It is not a fork and contains no upstream source code.

## What this project is

- Goal: local video frame interpolation + PS5 capture-card frame generation, with token shilling, cross-device streaming and subtitle translation stripped from the build.
- Method: upstream CMake feature flags (all default OFF). This repo selects the right ON/OFF set; it never deletes source files, because the upstream exe links every target into one binary.
- Upstream repo: https://github.com/Likely7/Veyra-NRVideo (GPL-3.0; Chiaki parts AGPL-3.0 + OpenSSL exception).

## Files

- `configure-lite.ps1` — PowerShell script that runs `cmake --preset` with the chosen flags. Validated with PowerShell parser and a DryRun smoke test; syntax is OK.
- `BUILD.md` — prerequisites, dependency roots, manual commands, build pitfalls.
- `USAGE.md` — frame-gen usage for local files, PS5, capture cards. Contains a confirmed device profile for UGREEN UG701 (P/N 45646).
- `README.md` — overview, included capability table, and honest caveats about DLSS 5 marketing.

## Key facts to preserve when editing

1. **Do not claim this uses official DLSS 5.** Upstream's own playbook says NVIDIA publishes no general DLSS 5 interface; the "DLSS 5" path is a community Feature 18 adapter (`nvngx_dlssnr.dll`) + IAT patch + arch spoof. Upstream README admits it is not vendor certified.
2. **Frame-gen algorithms are not in source.** They come from user-supplied proprietary NVIDIA DLLs and SDKs. Without them the build compiles but does nothing useful.
3. **Never promote any token.** Upstream README links a Pump.fun contract and the author acknowledges creator fees. This repo's docs must stay free of token references.
4. **Upstream is not fully done.** Its playbook admits Phase 5–7 incomplete, drift P95 2.8 s and GBV descriptor errors unresolved. Do not present README Highlights as accepted facts.
5. **FPS honesty.** Frame rate = source FPS × multiplier, capped by display refresh and GPU. `Submitted FPS` is neither physical refresh rate nor end-to-end latency — upstream states this explicitly.
6. **UG701 specifics**: USB-C / USB 3.2 Gen 1 (5 Gbps), capture up to 4K60 / 1440p144 / 1080p240, formats include P010 (10-bit HDR), no HDCP (PS5 must disable HDCP), 8K60 is passthrough only. Recommended PS5 profile: 1080p60 SDR, MJPEG or P010, BT.709 Limited, frame gen 2X.

## Editing conventions

- Docs are Markdown. Use GFM tables, fenced code blocks, no custom component tags.
- Keep claims tied to verifiable upstream sources. When something is unverified, say so plainly (e.g. "未实机编译验证").
- The canonical cloud copy of the README lives in WorkBuddy Library; local `*.md` files here are for version control only.
- The PowerShell script must stay runnable on PowerShell 5.1+. Re-run the parser check and a DryRun smoke test after any change.

## What NOT to add

- No token addresses, donation QR codes, or promotional links.
- No proprietary binaries, SDKs or model files — upstream excludes them from source Git and so must this repo.
- No claims of official NVIDIA certification or complete "DLSS 5" integration.
