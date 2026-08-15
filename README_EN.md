# Mac Gaming Toolbox

[简体中文](README.md) | [English](README_EN.md) | [日本語](README_JA.md)

Mac Gaming Toolbox is a modern macOS gaming enhancement and utility tool built natively with SwiftUI. Version **3.1.0** is optimized exclusively for **Apple Silicon (ARM64)** architecture, fully adhering to Apple's Human Interface Guidelines (HIG) with a native sidebar layout.

---

## 🌟 Key Features

### 1. Overview Dashboard & Real-time Monitoring
- **Live Status Hub**: Summarizes Metal HUD status, Caffeinate gaming focus mode, SteamDeck spoofing, and mounted external volumes.
- **Interfering Process Inspector**: Identifies game launchers and Wine processes running prior to HUD injection, allowing user-selected safe restarts.

### 2. Advanced Metal HUD Tuning & Per-App Profiles
- **Full Visual Parameter Customization**: 10%~100% scale, 0~100% opacity, and 4-corner screen positioning.
- **23 Granular Metrics**: Metric toggles with unit and value examples to build a personalized monitoring overlay.
- **Per-App HUD Profiles**: Bind distinct HUD configurations to individual games with 1-click launcher integration.
- **Performance Diagnostic Snapshot Exporter**: Generates structured Markdown hardware and performance reports for community sharing.

### 3. Game Boost & Controller Latency Optimization
- **Caffeinate Gaming Focus Mode**: Native `caffeinate` daemon preventing display sleep, idle sleep, and energy throttling during gaming and shader compilation.
- **macOS Game Mode & Controller Latency Tips**: Guidance on triggering full-screen Game Mode for doubled Bluetooth polling rates on DualSense/Xbox controllers and AirPods.
- **CrossOver / Wine Process Renice**: Elevates game processes to maximum system priority (renice -20).

### 4. Storage & Windows Save Game Finder
- **Windows Save Game Finder**: Automatically scans CrossOver, Whisky, Heroic, and Wine bottles for deep Windows save folders (`AppData/Local`, `Saved Games`, `My Games`).
- **1-Click Reveal & Zip Backup**: Reveal save folders in Finder or package them into standard `.zip` archives.
- **Custom Disk Mounts**: Mount external SSDs to game data paths to free internal disk space.
- **Safe Cache & Log Purge**: Safely clear redundant user caches with sensitive file protection enabled by default.

### 5. System Tools & Service Health Inspector
- **Software Service & Permission Health Inspector**: Inspects privileged helper XPC communication, background items permissions, Metal HUD environment, and storage access with 1-click auto-repair.
- **Streamlined Helper & App Icon Association**: Registered as `macgametoolbox.helper` and displays native App icon in macOS System Settings > Login Items & Extensions.
- **SteamDeck Hostname Spoofing**: Spoofs hostname to `steamdeck` for compatibility with specific anti-cheat whitelist mechanisms.

---

## 📋 Changelog (v3.1.0)

- **[UI Redesign]** Refactored UI completely to native macOS `NavigationSplitView` sidebar architecture and standard controls.
- **[Metal HUD Advanced]** Added 10%~100% scaling, opacity, 4-corner positioning, 23 metrics with unit examples, and per-app profiles.
- **[Performance Snapshots]** Added 1-click export of structured Markdown performance diagnosis reports.
- **[Process Manager]** Added interfering process inspector with user-selected safe restarts for reliable HUD injection.
- **[Save Game Finder]** Automatically scans and backs up Windows game saves inside CrossOver and Whisky bottles.
- **[Gaming Focus Mode]** Integrated native Caffeinate daemon to prevent sleep and throttling during gaming.
- **[Health Inspector]** Added Software Service & Permission Health Inspector with 1-click repair and legacy cleanup.
- **[Helper Streamlining]** Renamed helper to `macgametoolbox.helper` and bound native app icon in Login Items.
- **[Pure ARM64 Distribution]** Optimized exclusively for Apple Silicon ARM64 with lightweight Zip archive distribution.

---

## 💻 System Requirements

- macOS 14.0 (Sonoma) or later.
- Apple Silicon Mac (Native M1 / M2 / M3 / M4 support).
- Build Requirements: Swift 6, Xcode 16+, and Command Line Tools.

---

## 📦 Build & Packaging

### Release Build & Zip Packaging (ARM64 Only)

```bash
git clone https://github.com/Souitou-iop/mac-gaming-toolbox.git
cd mac-gaming-toolbox
ARCHS=arm64 ./Scripts/build-release.sh && ./Scripts/package-zip.sh "build/DerivedData/Build/Products/Release/Mac 游戏工具箱.app" "build/Mac 游戏工具箱-arm64.zip"
```

---

## 📄 License & Credits

- Licensed under [GNU General Public License v3.0](LICENSE).
- Original Project Author: **我是艾文喵**
  - Upstream Repository: [aiwentongxue/mac-gaming-toolbox](https://github.com/aiwentongxue/mac-gaming-toolbox)
  - Author Channels: [Bilibili](https://b23.tv/dV7YBJQ) · [YouTube](https://youtube.com/channel/UC0TgypOLHt2fXboVw34SKVQ)
