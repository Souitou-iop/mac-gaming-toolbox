# Changelog

All notable changes to **Mac 游戏工具箱 (Mac Gaming Toolbox)** will be documented in this file.

---

## [v3.1.0] - 2026-08-15

### 🚀 新特性与亮点 (Highlights)
- **侧边栏架构重构 (Native Sidebar UI)**：全面采用 `NavigationSplitView` 与原生 `GroupBox`、`LabeledContent` 控件，告别多层嵌套弹窗，符合 Apple HIG 标准。
- **全套自定义 Metal HUD 调优 (Granular Metal HUD Tuning)**：支持 10%~100% 缩放比例、0~100% 不透明度、屏幕四角方位、23 项精细化监控指标自由勾选（附带数值单位示例）与着色器/编码器时间线追踪。
- **单应用专属 HUD 方案 (Per-App Metal HUD Profiles)**：支持右键最近游戏卡片绑定专属 HUD 配置，启动时自动独立注入。
- **一键性能诊断快照导出 (Performance Diagnostic Snapshot Exporter)**：自动搜集系统版本、Apple Silicon 芯片规格、HUD 参数与 Wine 进程，一键导出结构化 Markdown 报告。
- **冲突进程排查与安全重启 (Interfering Process Manager)**：智能识别先于 HUD 启动的 Steam、CrossOver、Whisky、Wine 容器进程，支持用户自主勾选并安全重启服务。
- **Windows 游戏存档探测与备份 (Save Game Finder & Zip Backup)**：智能扫描 CrossOver、Whisky、Heroic、Wine 容器中的 `AppData/Local`、`Saved Games`、`My Games` 存档目录，支持一键在 Finder 中定位与打包为标准 `.zip` 归档。
- **原生 Caffeinate 游戏专注模式 (Gaming Focus Anti-Sleep Mode)**：内置原生 caffeinate 守护，游戏与着色器编译期间全程防休眠、防息屏与防降频，提供 Game Mode 蓝牙手柄低延迟优化。
- **软件服务与权限状态检测器 (Service & Permission Health Inspector)**：实时检测特权辅助服务通信、系统后台活动权限、Metal HUD 环境与磁盘读写权限，支持一键自动修复与历史残留服务清理。
- **多语言本地化支持 (Multi-Language Localization - ZH / EN / JA)**：完整支持简体中文、English 与日本語，支持跟随系统语言或在通用设置中自由切换，提供专属日文文档 `README_JA.md`。
- **HoYoGames 启动辅助卡片排版修复 (Layout Bug Fix)**：修复分段选择器压缩导致“等待：”竖向折字排版的视觉缺陷。
- **辅助服务精简与 App 图标关联 (Helper Streamlining)**：辅助服务标识符精简为 `macgametoolbox.helper`，在 macOS 系统设置「登录项与扩展」中正确显示主 App 原生图标。
- **纯 ARM64 无损 Zip 发布 (Apple Silicon ARM64 Exclusive & Zip Packaging)**：专为 Apple Silicon M 系列芯片编译优化，发布产物统一采用 `.zip` 格式分发。

---

## [v3.0.7] - 2026-08-12
- HoYoGames 启动帮助部分功能修复。

## [v3.0.6] - 2026-08-10
- 移除默认挂载路径数量限制，支持添加任意数量的默认路径。
- 默认路径保存、重新加载和旧配置导入不再截断为三项。

## [v3.0.5] - 2026-08-08
- 更新应用图标，采用铺满画布的蓝紫色背景。
- 移除磁盘挂载数量限制，支持选择、批量挂载和自动恢复任意数量的磁盘。
- 修复自动恢复将扫描次数误当成秒数的问题，改为按真实经过时间触发。
