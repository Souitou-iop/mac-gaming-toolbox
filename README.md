# Mac 游戏工具箱 (Mac Gaming Toolbox)

[简体中文](README.md) | [English](README_EN.md) | [日本語](README_JA.md)

Mac 游戏工具箱是一款基于原生 SwiftUI 打造的现代化 macOS 游戏辅助与优化工具。当前版本为 **3.1.0**，专为 **Apple Silicon (ARM64)** 架构深度定制与优化，界面完全遵循 Apple HIG 人机交互指南，提供侧边栏多功能聚合体验。

---

## 🌟 核心功能一览

### 1. 概览仪表盘与实时状态监控
- **状态看板**：实时汇总 Metal HUD 状态、Caffeinate 游戏专注模式、SteamDeck 伪装状态及外接磁盘挂载数量。
- **冲突进程排查**：智能排查先于 HUD 启动的 Steam、CrossOver、Whisky、Wine 容器进程，支持用户自主勾选并安全重启服务。

### 2. Metal HUD 深度调优与单应用方案
- **全方位视觉参数定制**：支持 10%~100% 缩放比例、0~100% 不透明度调节、屏幕四角方位自由切换。
- **23 项监控指标精细化勾选**：附带数值与单位示例，随心定制专属 HUD 监控面板。
- **单应用专属 HUD 方案 (Per-App Profiles)**：右键最近游戏卡片即可将当前 HUD 参数绑定为该游戏的专属配置，启动时自动套用。
- **一键导出性能快照报告**：一键生成结构化 Markdown 性能诊断报告，方便向社区反馈硬件表现。

### 3. 游戏加速与手柄低延迟优化
- **原生 Caffeinate 游戏专注模式**：一键开启系统原生 `caffeinate` 守护，游戏与着色器编译期间全程防休眠、防息屏与防能耗降频。
- **macOS Game Mode 唤醒与手柄低延迟**：提供 PS5/Xbox 蓝牙手柄与 AirPods 双倍采样轮询率科普与全屏独占优化建议。
- **CrossOver / Wine 进程最高优先级调度**：支持将 Wine 游戏进程调整至系统最高优先级 (renice -20)。

### 4. 存储与 Windows 游戏存档管理
- **Windows 游戏存档探测器 (Game Save Finder)**：自动扫描 CrossOver、Whisky、Heroic 及 Wine 容器中的深层 Windows 存档目录（`AppData/Local`、`Saved Games`、`My Games`）。
- **一键定位与 Zip 备份**：支持在 Finder 中秒级高亮打开存档目录，或一键打包备份为标准 `.zip` 归档。
- **外接磁盘自定挂载点**：自定义外接 SSD 挂载路径，释放内置硬盘空间。
- **安全缓存与日志清理**：支持默认敏感文件排除保护，安全释放系统空间。

### 5. 系统工具与服务状态体检
- **软件服务与权限状态检测器**：实时检测特权辅助服务通信、系统后台活动权限、Metal HUD 环境与磁盘读写权限，支持一键自动修复与历史残留清理。
- **辅助服务精简与图标关联**：辅助服务标识符精简为 `macgametoolbox.helper`，macOS 系统设置正确展示主 App 原生图标。
- **SteamDeck 反作弊环境伪装**：一键切换或恢复 Mac 主机名以兼容部分反作弊机制。

---

## 📋 更新日志 (v3.1.0)

- **【UI 重构】** 全面采用 macOS 原生 `NavigationSplitView` 侧边栏架构与标准控件，告别多层嵌套弹窗。
- **【Metal HUD 进阶】** 支持 10%~100% 缩放、透明度、四角方位、23 项指标（带数值单位示例）与单应用专属方案绑定。
- **【性能诊断快照】** 支持一键生成结构化 Markdown 性能诊断报告，方便社区反馈与硬件评估。
- **【进程排查与重启】** 智能排查先于 HUD 启动的冲突进程（Steam、CrossOver、Wine），支持用户自主勾选安全重启。
- **【存档管理】** 自动扫描 CrossOver、Whisky、Wine 容器深层存档（AppData、Saved Games），支持一键定位与 Zip 备份。
- **【游戏专注模式】** 内置原生 Caffeinate 守护进程，游戏与着色器编译期间全程防休眠、防息屏与防降频。
- **【服务状态体检】** 新增软件服务与权限状态检测器，支持一键自动修复与历史残留服务清理。
- **【辅助服务精简】** 辅助服务标识符精简为 `macgametoolbox.helper`，系统后台活动正确显示 App 图标。
- **【纯 ARM64 分发】** 全面迁移至 Apple Silicon 纯原生构建，发布包统一采用无损 Zip 格式分发。

---

## 💻 系统要求

- macOS 14.0 (Sonoma) 或更高版本。
- Apple Silicon Mac (M1 / M2 / M3 / M4 系列芯片原生支持)。
- 构建要求：Swift 6、Xcode 16+ 及 Command Line Tools。

---

## 📦 安装与构建

### 运行 Release 构建并打包 Zip (纯 ARM64)

```bash
git clone https://github.com/Souitou-iop/mac-gaming-toolbox.git
cd mac-gaming-toolbox
ARCHS=arm64 ./Scripts/build-release.sh && ./Scripts/package-zip.sh "build/DerivedData/Build/Products/Release/Mac 游戏工具箱.app" "build/Mac 游戏工具箱-arm64.zip"
```

---

## 📄 开源许可与致谢

- 本项目遵循 [GNU General Public License v3.0](LICENSE) 开源。
- 原项目作者：**我是艾文喵**
  - 原项目仓库：[aiwentongxue/mac-gaming-toolbox](https://github.com/aiwentongxue/mac-gaming-toolbox)
  - 作者主页：[哔哩哔哩](https://b23.tv/dV7YBJQ) · [YouTube](https://youtube.com/channel/UC0TgypOLHt2fXboVw34SKVQ)
