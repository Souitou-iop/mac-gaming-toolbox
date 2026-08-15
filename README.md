# Mac 游戏工具箱 (Mac Gaming Toolbox) - 增强分支版

[简体中文](README.md) | [English](README_EN.md) | [日本語](README_JA.md)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014.0%2B-lightgrey.svg)](https://apple.com/macos)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20(ARM64)-brightgreen.svg)](https://apple.com/mac)
[![Release](https://img.shields.io/badge/Release-v3.1.0-orange.svg)](https://github.com/Souitou-iop/mac-gaming-toolbox/releases)

> **关于本仓库**：本项目是基于原作者 **[@我是艾文喵](https://github.com/aiwentongxue)** 的开源项目 [aiwentongxue/mac-gaming-toolbox](https://github.com/aiwentongxue/mac-gaming-toolbox) 进行深度重构与功能扩展的 Fork 分支版本。

---

## 💖 致谢原作者 (Credits & Acknowledgements)

本项目首先向原作者 **我是艾文喵** 表达由衷的敬意与感谢！原项目为广大 Mac 游戏玩家探索 Apple Silicon 游戏生态、Wine / GPTK 转译与游戏优化奠定了坚实的基础。

- **原项目开源仓库**：[aiwentongxue/mac-gaming-toolbox](https://github.com/aiwentongxue/mac-gaming-toolbox)
- **原作者哔哩哔哩主页**：[我是艾文喵 (Bilibili)](https://b23.tv/dV7YBJQ)
- **原作者 YouTube 频道**：[我是艾文喵 (YouTube)](https://youtube.com/channel/UC0TgypOLHt2fXboVw34SKVQ)
- **官方视频发布教程**：[B站重磅发布教程](https://b23.tv/qnJBcbk) · [YouTube 视频教程](https://youtu.be/Y9g4F0_6ipI?si=i3G9dxiXMbk2NSzY)

---

## 🚀 相比原版的增强与重构功能 (Fork Enhancements)

本分支在保持原版核心功能的基础上，针对界面交互、游戏性能监视、容器存档管理、运行稳定性与现代 macOS 体验进行了全方位的大幅增强：

### 1. 🎨 原生侧边栏 UI 重构 (Native macOS Sidebar Architecture)
- 告别旧版本的弹窗堆叠与多层嵌套对话框，全面采用 Apple HIG 标准的 `NavigationSplitView` 侧边栏布局。
- 采用原生标准 `GroupBox` 与控件体系，原生响应系统深色/浅色外观切换，轻量、丝滑且无视觉侵入。

### 2. 📊 深度 Metal HUD 参数调优与 23 项指标 (Granular Metal HUD Tuning)
- **视觉全控**：支持 10%~100% 缩放比例、0~100% 透明度调节、屏幕四角（右上/左上/右下/左下）方位切换。
- **23 项指标精细化勾选**：每项指标均配有中文解释与**实际数值/单位示例**（如 FPS、GPU 耗时、呈现延迟、图层缩放、着色器编译等）。
- **高阶追踪**：支持 HUD 调试日志输出、着色器编译日志与 GPU 编码器时间线追踪。

### 3. 🎯 单应用专属 HUD 方案 (Per-App Metal HUD Profiles)
- 支持为不同游戏绑定专属 HUD 参数（例如竞技游戏仅显示精简 FPS，3A 大作显示完整 GPU 与着色器分析）。
- 在「最近游戏」卡片上右键即可一键保存专属方案，启动时自动独立注入生效。

### 4. 📝 一键性能诊断快照导出 (Performance Diagnostic Snapshot)
- 一键自动搜集 macOS 系统版本、Apple Silicon 芯片规格、当前 HUD 配置与 Wine 进程状态。
- 生成规范的 Markdown 性能报告，方便在 GitHub、Reddit、Discord 或游戏论坛中交流与排查帧率异常。

### 5. 🔍 冲突进程排查与安全重启 (Interfering Process Manager)
- 智能识别在开启 HUD 前就已经常驻后台的 Steam、CrossOver、Whisky 及 Wine 容器进程。
- 提供可视化勾选列表，一键平滑重启冲突进程，彻底解决“开启 HUD 后进游戏不显示”的痛点。

### 6. 💾 Windows 游戏存档探测与一键 Zip 备份 (Game Save Finder)
- 智能探测 CrossOver、Whisky、Heroic 及各类 Wine 容器中的深层 Windows 游戏存档目录（涵盖 `AppData/Local`、`Saved Games`、`My Games` 等）。
- 支持一键在访达 (Finder) 中高亮打开存档目录，或直接打包导出为标准 `.zip` 归档，防止重装容器或更新游戏丢失存档。

### 7. ☕ Caffeinate 原生游戏专注模式 (Gaming Focus Anti-Sleep Mode)
- 调动系统底层 `caffeinate` 守护进程，在游戏游玩、挂机或着色器编译期间，全程阻止屏幕变暗、系统待机与空闲降频。
- 科普并引导激活 macOS 游戏模式 (Game Mode)，将 PS5/Xbox 蓝牙手柄与 AirPods 采样率翻倍，大幅降低输入延迟。

### 8. 🛡️ 零弹窗服务体检与历史残留清理 (Health Inspector)
- **零弹窗无感启动**：应用启动时进行 100% 只读被动体检，**绝不主动弹管理员密码窗**；仅在用户使用提权功能或手动点击安装时才发起授权。
- **历史残留清理**：自动探测并清理旧版本遗留的 Helper 守护进程与残留文件。
- **系统图标关联**：特权服务标识符规范化为 `macgametoolbox.helper`，在系统设置「登录项与扩展」中正确显示主 App 图标。

### 9. 🌐 完整多语言动态切换 (ZH / EN / JA)
- 完整支持**简体中文**、**English** 与**日本語**。
- 支持跟随系统语言自动切换，亦可在设置面板中自由手动切换。

### 10. ⚡ 纯 Apple Silicon ARM64 编译与单包 Zip 分发
- 剔除冗余架构，专为 Apple Silicon (M1/M2/M3/M4) 进行纯原生编译，体积更小、启动更快。
- 严格采用单一纯净 `.zip` 压缩包分发，解压即可直接拖入「应用程序」运行。

---

## 📋 功能对比表 (Comparison)

| 功能特性 | 原版 (Upstream) | 本 Fork 增强版 (v3.1.0) |
| :--- | :---: | :---: |
| **界面架构** | 传统浮窗 / 弹窗堆叠 | 现代化 原生侧边栏 (`NavigationSplitView`) |
| **启动体验** | 启动时可能触发提权授权弹窗 | **零弹窗无感启动**（完全只读体检，按需授权） |
| **Metal HUD 调优** | 全局开关 / 基础启动 | **缩放、透明度、四角方位、23 项指标带单位示例** |
| **单 App HUD 方案** | 仅快捷启动单个 App | **游戏独立专属 HUD 配置绑定** |
| **性能诊断导出** | 导出普通运行日志 | **一键生成结构化 Markdown 性能诊断快照** |
| **HUD 冲突进程排查** | 无 | **自动扫描常驻启动器与 Wine 进程并支持安全重启** |
| **Windows 存档管理** | 无 | **自动扫描 AppData/SavedGames，一键定位与 Zip 备份** |
| **防休眠与降频** | 无 | **内置 Caffeinate 原生游戏专注防休眠模式** |
| **多语言支持** | 中文 / 基础英文 | **简体中文 / English / 日本語（支持动态即时切换）** |
| **架构与分发** | 通用二进制 | **纯 Apple Silicon ARM64 编译，轻量单一 Zip 分发** |

---

## 💻 运行与系统要求

- **操作系统**：macOS 14.0 (Sonoma) 或更高版本
- **硬件架构**：Apple Silicon (M1 / M2 / M3 / M4 系列芯片)
- **编译环境**：Xcode 16+、Swift 6 及 Command Line Tools

---

## 📦 本地编译与打包

如果你希望自行从源代码构建安装包，请执行以下命令：

```bash
# 1. 克隆本仓库
git clone https://github.com/Souitou-iop/mac-gaming-toolbox.git
cd mac-gaming-toolbox

# 2. 运行自动化发布脚本（编译并打包为纯 ARM64 的 Zip 安装包）
ARCHS=arm64 ./Scripts/build-release.sh && ./Scripts/package-zip.sh "build/DerivedData/Build/Products/Release/Mac 游戏工具箱.app" "build/Mac 游戏工具箱-arm64.zip"
```

构建完成后，单一安装包将生成在 `build/Mac 游戏工具箱-arm64.zip`。

---

## 📄 开源许可证

本项目遵循 **GNU General Public License v3.0 (GPL-3.0)** 许可证开源。详细信息请参阅 [LICENSE](LICENSE) 文件。
