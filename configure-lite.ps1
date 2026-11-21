# Veyra Lite - configure script
# Run from the upstream Veyra-NRVideo repo root (PowerShell 5.1+).
# Copy this file into the repo root first, then: .\configure-lite.ps1
#
# It configures a clean frame-generation-only build using the upstream's own
# feature flags. No source files are modified.

[CmdletBinding()]
param(
    [string] $Preset = "x64-release",

    # Required for PS5 Remote Play (Chiaki). Build script docs call these
    # VEYRA_RP_CHIAKI_SOURCE_DIR / VEYRA_RP_CHIAKI_VERIFY_DIR.
    [string] $ChiakiSourceDir = "",
    [string] $ChiakiVerifyDir = "",

    # Optional: only if you want the experimental Feature-18 NR adapter.
    [string] $DlssSdkRoot = "",

    # Auto-detected from third_party_local/nvidia/ if left empty.
    [string] $NvofSdkRoot = "",

    # vcpkg x64-windows root containing FFmpeg.
    [string] $FfmpegRoot = "",

    # Set to keep the experimental local DLSS-NR (not needed for frame gen).
    [switch] $WithExperimentalNr,

    # Set to keep Moonlight / Xbox streaming backends (off by default here).
    [switch] $WithAllStreaming,

    # Only print the cmake command instead of running it.
    [switch] $DryRun
)

$ErrorActionPreference = "Stop"

$flags = [ordered]@{
    # --- frame generation core (ON) ---
    "VEYRA_ENABLE_DLSS_FG"             = "ON"
    "VEYRA_ENABLE_NVOF"                = "ON"
    "VEYRA_ENABLE_REMOTEPLAY"          = "ON"
    "VEYRA_ENABLE_DLSS_SR"             = "ON"

    # --- stripped from this clean build (OFF) ---
    "VEYRA_ENABLE_MOONLIGHT"           = "OFF"
    "VEYRA_ENABLE_XBOX"                = "OFF"
    "VEYRA_ENABLE_LIBDOVI"             = "OFF"
    "VEYRA_ENABLE_DEINTERLACE"         = "OFF"
    "VEYRA_ENABLE_EXPERIMENTAL_DLSSNR" = "OFF"
    "VEYRA_ENABLE_D3D12_DEBUG"         = "OFF"
}

if ($WithExperimentalNr) {
    $flags["VEYRA_ENABLE_EXPERIMENTAL_DLSSNR"] = "ON"
    if ([string]::IsNullOrWhiteSpace($DlssSdkRoot)) {
        throw "WithExperimentalNr needs -DlssSdkRoot (path with include/nvsdk_ngx.h)."
    }
}
if ($WithAllStreaming) {
    $flags["VEYRA_ENABLE_MOONLIGHT"] = "ON"
    $flags["VEYRA_ENABLE_XBOX"] = "ON"
}

if (-not (Test-Path "CMakeLists.txt")) {
    throw "Run this script from the Veyra-NRVideo repo root (CMakeLists.txt not found)."
}

$cmakeArgs = [System.Collections.Generic.List[string]]::new()
$cmakeArgs.Add("--preset"); $cmakeArgs.Add($Preset)
foreach ($k in $flags.Keys) {
    $cmakeArgs.Add("-D$k=$($flags[$k])")
}

function AddPathArg($name, $value) {
    if (-not [string]::IsNullOrWhiteSpace($value)) {
        if (-not (Test-Path $value)) { throw "$name path does not exist: $value" }
        $script:cmakeArgs.Add("-D$name=$value")
    }
}

AddPathArg "VEYRA_RP_CHIAKI_SOURCE_DIR" $ChiakiSourceDir
AddPathArg "VEYRA_RP_CHIAKI_VERIFY_DIR" $ChiakiVerifyDir
AddPathArg "VEYRA_DLSS_SDK_ROOT" $DlssSdkRoot
AddPathArg "VEYRA_NVOF_SDK_ROOT" $NvofSdkRoot
AddPathArg "VEYRA_FFMPEG_ROOT" $FfmpegRoot

if (-not $ChiakiSourceDir -and $flags["VEYRA_ENABLE_REMOTEPLAY"] -eq "ON") {
    Write-Warning "PS5 Remote Play is ON but -ChiakiSourceDir was not given. Configure may fail; see BUILD.md."
}

$cmd = "cmake " + ($cmakeArgs -join " ")
Write-Host $cmd

if (-not $DryRun) {
    & cmake $cmakeArgs
    if ($LASTEXITCODE -ne 0) { throw "cmake configure failed (exit $LASTEXITCODE)." }
    & cmake --build --preset $Preset --target veyra_qml_ui
    if ($LASTEXITCODE -ne 0) { throw "build failed (exit $LASTEXITCODE)." }
    Write-Host "Built. See BUILD.md for the runtime file layout."
}
