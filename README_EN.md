# Mac Gaming Toolbox - Enhanced Fork Edition

[简体中文](README.md) | [English](README_EN.md) | [日本語](README_JA.md)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014.0%2B-lightgrey.svg)](https://apple.com/macos)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20(ARM64)-brightgreen.svg)](https://apple.com/mac)
[![Release](https://img.shields.io/badge/Release-v3.1.0-orange.svg)](https://github.com/Souitou-iop/mac-gaming-toolbox/releases)

> **About this repository**: This project is an enhanced and refactored fork based on the original open-source utility created by **[@我是艾文喵 (Iven)](https://github.com/aiwentongxue)**: [aiwentongxue/mac-gaming-toolbox](https://github.com/aiwentongxue/mac-gaming-toolbox).

---

## 💖 Credits & Acknowledgements

We extend our sincere gratitude and highest respect to the original author, **我是艾文喵 (Iven)**! The original project laid an exceptional foundation for the Mac gaming community, exploring Apple Silicon translation layers, Wine/GPTK integration, and macOS gaming optimization.

- **Upstream Repository**: [aiwentongxue/mac-gaming-toolbox](https://github.com/aiwentongxue/mac-gaming-toolbox)
- **Author's Bilibili Channel**: [我是艾文喵 (Bilibili)](https://b23.tv/dV7YBJQ)
- **Author's YouTube Channel**: [我是艾文喵 (YouTube)](https://youtube.com/channel/UC0TgypOLHt2fXboVw34SKVQ)
- **Official Video Guides**: [Bilibili Release Video](https://b23.tv/qnJBcbk) · [YouTube Video Guide](https://youtu.be/Y9g4F0_6ipI?si=i3G9dxiXMbk2NSzY)

---

## 🚀 Key Enhancements in this Fork Edition

While preserving all core capabilities of the upstream utility, this fork introduces extensive architectural, performance, and user experience enhancements tailored for modern macOS and Apple Silicon:

### 1. 🎨 Native macOS Sidebar UI Architecture
- Completely replaces legacy dialogs and modal sheets with a native `NavigationSplitView` sidebar layout adhering strictly to Apple's Human Interface Guidelines (HIG).
- Uses standard native `GroupBox` and UI components with seamless dark/light mode switching.

### 2. 📊 Granular Metal HUD Tuning & 23 Metrics
- **Visual Controls**: Full control over scale (10%~100%), opacity (0~100%), and 4-corner screen positioning (Top-Right, Top-Left, Bottom-Right, Bottom-Left).
- **23 Granular Metric Toggles**: Each metric is documented with clear descriptions and **real-world unit/value examples** (FPS, GPU time, present delay, layer scale, shader compilation, etc.).
- **Advanced Tracing**: Toggle HUD debug logging, shader compilation activity, and GPU encoder timeline graphs.

### 3. 🎯 Per-App Metal HUD Profiles
- Bind distinct HUD configurations to individual games (e.g., lightweight FPS counter for competitive titles, full GPU/shader diagnostics for AAA titles).
- Right-click any title in the Recent Games list to save current settings as that game's permanent profile.

### 4. 📝 1-Click Performance Snapshot Exporter
- Automatically aggregates macOS version, Apple Silicon chip specs, active HUD parameters, and Wine processes.
- Exports a standardized Markdown (`.md`) diagnostic snapshot report for community troubleshooting on Discord, Reddit, or GitHub.

### 5. 🔍 Interfering Process Inspector & Safe Restarts
- Automatically detects game launchers (Steam, CrossOver, Whisky, Heroic) and background Wine processes that were running prior to HUD injection.
- Provides a checklist for one-click safe restarts, eliminating the common "HUD not showing in game" issue.

### 6. 💾 Windows Game Save Finder & 1-Click Zip Backup
- Automatically scans CrossOver, Whisky, Heroic, and custom Wine prefixes for deep Windows save folders (`AppData/Local`, `Saved Games`, `My Games`).
- Supports 1-click **Reveal in Finder** or direct packaging into standard `.zip` archives to safeguard saves against bottle reinstalls.

### 7. ☕ Caffeinate Native Gaming Focus Mode
- Leverages the native macOS `caffeinate` daemon to prevent display dimming, idle sleep, and CPU energy throttling during gameplay and shader compilation.
- Provides guidance on macOS Game Mode to double Bluetooth polling rates for DualSense/Xbox gamepads and AirPods, halving wireless latency.

### 8. 🛡️ Passive Zero-Prompt Health Check & Legacy Cleanup
- **Zero Startup Prompts**: Performs a 100% passive, read-only system inspection on launch **without annoying password prompts**; authorization is requested only on-demand when using privileged features or manual repair.
- **Legacy Residuals Cleaner**: Detects and cleans up leftover helper daemons and files from older versions.
- **System Icon Association**: The privileged helper is streamlined to `macgametoolbox.helper`, displaying the native app icon in macOS System Settings > Login Items & Extensions.

### 9. 🌐 Full Dynamic Tri-Lingual Localization (ZH / EN / JA)
- Comprehensive localization across **Simplified Chinese**, **English**, and **Japanese**.
- Supports automatic system language matching as well as real-time in-app switching from the Settings panel.

### 10. ⚡ Pure Apple Silicon ARM64 Build & Single Zip Distribution
- Stripped of legacy x86_64 bloat; compiled exclusively for Apple Silicon (M1/M2/M3/M4) for minimal footprint and maximum speed.
- Distributed strictly as a single, lightweight `.zip` archive.

---

## 📋 Feature Comparison Table

| Feature / Capability | Upstream (Original) | Enhanced Fork (v3.1.0) |
| :--- | :---: | :---: |
| **UI Architecture** | Legacy Floating Windows / Sheets | Modern Native Sidebar (`NavigationSplitView`) |
| **Startup Behavior** | May prompt for admin password on launch | **100% Passive Read-Only Check (Zero Prompts)** |
| **Metal HUD Controls** | Global Switch / Basic Launch | **Scale, Opacity, 4 Corners, 23 Metrics with Examples** |
| **Per-App HUD Profiles** | Basic single-app launch | **Custom HUD profile binding per game** |
| **Performance Reports** | Standard log export | **1-Click structured Markdown performance snapshots** |
| **Interfering Processes** | None | **Automated detection & safe restart checklist** |
| **Save Game Management** | None | **Automatic AppData scan, Finder reveal & Zip backup** |
| **Anti-Sleep / Throttling**| None | **Native Caffeinate Gaming Focus Mode** |
| **Multi-Language** | Chinese / Basic English | **Simplified Chinese / English / Japanese (Dynamic)** |
| **Build & Distribution** | Universal Binary | **Pure Apple Silicon ARM64, single clean Zip archive** |

---

## 💻 System Requirements

- **Operating System**: macOS 14.0 (Sonoma) or later
- **Architecture**: Apple Silicon (M1 / M2 / M3 / M4 chips)
- **Build Requirements**: Xcode 16+, Swift 6, and Command Line Tools

---

## 📦 Build from Source

To compile and package the release distribution locally:

```bash
# 1. Clone this repository
git clone https://github.com/Souitou-iop/mac-gaming-toolbox.git
cd mac-gaming-toolbox

# 2. Run the release build and packaging script (Pure ARM64 Zip)
ARCHS=arm64 ./Scripts/build-release.sh && ./Scripts/package-zip.sh "build/DerivedData/Build/Products/Release/Mac 游戏工具箱.app" "build/Mac 游戏工具箱-arm64.zip"
```

The single archive will be generated at `build/Mac 游戏工具箱-arm64.zip`.

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**. See the [LICENSE](LICENSE) file for details.
