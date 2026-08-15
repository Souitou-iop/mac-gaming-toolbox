import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import MacGameToolboxCore
#endif

public struct MetalHUDSectionView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingProcessManagerSheet = false
    @State private var showingResetConfirm = false
    @State private var activeTab: TunerTab = .appearance
    @State private var showingAppPicker = false

    enum TunerTab: String, CaseIterable, Identifiable {
        case appearance = "外观与布局"
        case metrics = "监控指标"
        case advanced = "高级与日志"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .appearance: return "slider.horizontal.3"
            case .metrics: return "chart.xyaxis.line"
            case .advanced: return "gearshape.2.fill"
            }
        }
    }

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            GamingSectionHeader(
                icon: "gauge.with.dots.needle.67percent",
                title: tr("Metal HUD 性能监视器", "Metal HUD Performance Monitor"),
                subtitle: tr("实时帧率、GPU/CPU 负载、着色器与图形管线诊断工具", "Real-time FPS, GPU/CPU load, shaders and Metal pipeline diagnostics"),
                accentColor: GamingTheme.neonEmerald
            )

            // Master Control & Quick Actions Hero Card
            masterControlCard

            // Process Detection & Conflict Warning Banner
            conflictProcessCard

            // Embedded Tuner Controls
            tunerModuleCard

            // Recent Apps Grid
            recentAppsCard
        }
        .confirmationDialog(
            tr("确定要重置全部 Metal HUD 配置吗？", "Reset all Metal HUD settings?"),
            isPresented: $showingResetConfirm,
            titleVisibility: .visible
        ) {
            Button(tr("重置全部配置", "Reset All"), role: .destructive) { model.resetMetalHUDOptions() }
            Button(tr("取消", "Cancel"), role: .cancel) {}
        } message: {
            Text(tr("所有外观、指标、日志与高级设置将恢复为默认值。", "All appearance, metrics, logs and advanced settings will return to defaults."))
        }
    }

    // MARK: - Master Control Card

    private var masterControlCard: some View {
        GamingGlassCard(isActive: model.metalHUDEnabled, padding: 18) {
            VStack(spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(model.metalHUDEnabled ? GamingTheme.neonEmerald.opacity(0.18) : Color.white.opacity(0.06))
                            .frame(width: 44, height: 44)
                        Image(systemName: "gauge.with.dots.needle.67percent")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(model.metalHUDEnabled ? GamingTheme.neonEmerald : Color.secondary)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(tr("全局 Metal HUD 注入", "Global Metal HUD Injection"))
                                .font(.headline)
                            LiveStatusBadge(model.metalHUDEnabled ? .active : .idle)
                        }
                        Text(tr("开启后，新启动的原生 Mac 游戏及 Wine / GPTK 游戏将实时渲染性能面板",
                                "When enabled, newly launched Mac & Wine/GPTK games display the real-time HUD overlay."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { model.metalHUDEnabled },
                        set: { model.setMetalHUD($0) }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }

                Divider().opacity(0.3)

                HStack(spacing: 10) {
                    Button {
                        model.launchAppWithMetalHUD()
                    } label: {
                        Label(tr("为单个 App 注入启动", "Launch App with HUD"), systemImage: "plus.app.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(GamingTheme.electricViolet)
                    .controlSize(.regular)

                    Button {
                        model.openMetalHUDProcessManager()
                    } label: {
                        Label(tr("排查冲突进程", "Check Processes"), systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                    Spacer()

                    Button(role: .destructive) {
                        showingResetConfirm = true
                    } label: {
                        Label(tr("重置默认", "Reset"), systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .controlSize(.small)
                }
            }
        }
    }

    // MARK: - Conflict Process Card

    private var conflictProcessCard: some View {
        GamingGlassCard(cornerRadius: 14, padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(GamingTheme.cyberCyan)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tr("修改即时生效提醒", "Real-Time Sync Notice"))
                        .font(.subheadline.bold())
                    Text(tr("参数调整已实时写入系统环境。若游戏已经在运行中，请通过「排查冲突进程」关闭对应后台进程后重新启动。",
                            "Settings are synced in real-time. If a game is already running, terminate its process and restart it."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(tr("快速排查", "Quick Check")) {
                    model.openMetalHUDProcessManager()
                }
                .controlSize(.small)
            }
        }
    }

    // MARK: - Embedded Tuner Module Card

    private var tunerModuleCard: some View {
        GamingGlassCard(cornerRadius: 16, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                // Tab picker & Preset chips
                HStack(alignment: .center) {
                    Picker("", selection: $activeTab) {
                        ForEach(TunerTab.allCases) { tab in
                            Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 320)

                    Spacer()

                    // Presets
                    HStack(spacing: 6) {
                        Text(tr("预设：", "Preset:"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        presetButton("精简", .minimal)
                        presetButton("均衡", .balanced)
                        presetButton("完整", .complex)
                    }
                }

                Divider().opacity(0.3)

                // Tab Content
                switch activeTab {
                case .appearance:
                    appearanceTabContent
                case .metrics:
                    metricsTabContent
                case .advanced:
                    advancedTabContent
                }
            }
        }
    }

    // MARK: - Appearance Tab

    private var appearanceTabContent: some View {
        VStack(spacing: 14) {
            // Scale slider
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tr("缩放比例 (Scale)", "Scale"))
                        .font(.subheadline.bold())
                    Text(tr("调整 HUD 在屏幕上的整体显示尺寸", "Adjust overall size of HUD on screen"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 170, alignment: .leading)

                Slider(
                    value: Binding(
                        get: { model.configuration.metalHUDOptions.scale },
                        set: { var opts = model.configuration.metalHUDOptions; opts.scale = $0; model.updateMetalHUDOptions(opts) }
                    ),
                    in: 0.1...1.0,
                    step: 0.05
                )

                Text(String(format: "%.0f%%", model.configuration.metalHUDOptions.scale * 100))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .frame(width: 50, alignment: .trailing)
            }

            // Opacity slider
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tr("不透明度 (Opacity)", "Opacity"))
                        .font(.subheadline.bold())
                    Text(tr("调整 HUD 背景与文本的不透明度", "Adjust HUD background opacity"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 170, alignment: .leading)

                Slider(
                    value: Binding(
                        get: { model.configuration.metalHUDOptions.opacity },
                        set: { var opts = model.configuration.metalHUDOptions; opts.opacity = $0; model.updateMetalHUDOptions(opts) }
                    ),
                    in: 0.0...1.0,
                    step: 0.05
                )

                Text(String(format: "%.0f%%", model.configuration.metalHUDOptions.opacity * 100))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .frame(width: 50, alignment: .trailing)
            }

            // Alignment picker
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tr("显示方位 (Alignment)", "Alignment"))
                        .font(.subheadline.bold())
                    Text(tr("HUD 悬浮停靠的屏幕角落位置", "Corner of the screen where HUD is pinned"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 170, alignment: .leading)

                Picker("", selection: Binding(
                    get: { model.configuration.metalHUDOptions.alignment },
                    set: { var opts = model.configuration.metalHUDOptions; opts.alignment = $0; model.updateMetalHUDOptions(opts) }
                )) {
                    Text(tr("左上角", "Top Left")).tag("topleft")
                    Text(tr("右上角 (默认)", "Top Right (Default)")).tag("topright")
                    Text(tr("左下角", "Bottom Left")).tag("bottomleft")
                    Text(tr("右下角", "Bottom Right")).tag("bottomright")
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Metrics Tab

    private var metricsTabContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tr("勾选需要实时监控的数据指标：", "Select metrics to display:"))
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 8)], spacing: 8) {
                ForEach(MetalHUDElement.allElements, id: \.raw) { (element: MetalHUDElement) in
                    let isChecked = model.configuration.metalHUDOptions.elements.contains(element.raw)
                    Button {
                        var opts = model.configuration.metalHUDOptions
                        if isChecked {
                            opts.elements.removeAll { $0 == element.raw }
                        } else {
                            opts.elements.append(element.raw)
                        }
                        model.updateMetalHUDOptions(opts)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                                .foregroundStyle(isChecked ? GamingTheme.neonEmerald : .secondary)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(tr(element.zh, element.en))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(isChecked ? .primary : .secondary)
                                Text(element.raw)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isChecked ? GamingTheme.neonEmerald.opacity(0.1) : Color.white.opacity(0.03))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(isChecked ? GamingTheme.neonEmerald.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Advanced Tab

    private var advancedTabContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(tr("输出 HUD 调试日志 (Log Enabled)", "HUD Debug Logging"), isOn: Binding(
                get: { model.configuration.metalHUDOptions.logEnabled },
                set: { var opts = model.configuration.metalHUDOptions; opts.logEnabled = $0; model.updateMetalHUDOptions(opts) }
            ))

            Toggle(tr("输出着色器编译日志 (Shader Log Enabled)", "Shader Compile Logging"), isOn: Binding(
                get: { model.configuration.metalHUDOptions.shaderLogEnabled },
                set: { var opts = model.configuration.metalHUDOptions; opts.shaderLogEnabled = $0; model.updateMetalHUDOptions(opts) }
            ))

            Toggle(tr("编码器时间线分析 (Encoder Timing)", "Encoder Timeline Profiling"), isOn: Binding(
                get: { model.configuration.metalHUDOptions.encoderTimingEnabled },
                set: { var opts = model.configuration.metalHUDOptions; opts.encoderTimingEnabled = $0; model.updateMetalHUDOptions(opts) }
            ))

            HStack {
                Button {
                    model.exportRecentHUDLogs()
                } label: {
                    Label(tr("导出最近 10 分钟 Metal HUD 日志", "Export Metal HUD Logs"), systemImage: "square.and.arrow.up")
                }
                .controlSize(.small)
            }
            .padding(.top, 4)
        }
        .font(.subheadline)
    }

    // MARK: - Recent Apps Card

    private var recentAppsCard: some View {
        GamingGlassCard(cornerRadius: 16, padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(tr("最近使用 Metal HUD 启动的 App", "Recent Metal HUD Apps"))
                        .font(.headline)
                    Spacer()
                    if !model.configuration.recentMetalHUDApps.isEmpty {
                        Text(tr("\(model.configuration.recentMetalHUDApps.count) 个记录", "\(model.configuration.recentMetalHUDApps.count) apps"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if model.configuration.recentMetalHUDApps.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "gamecontroller")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                            Text(tr("暂无记录，点击上方「为单个 App 注入启动」即可快速录入", "No recent apps. Click 'Launch App with HUD' above."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 16)
                        Spacer()
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 12)], spacing: 12) {
                        ForEach(model.configuration.recentMetalHUDApps) { app in
                            Button {
                                model.launchRecordedAppWithMetalHUD(app.path)
                            } label: {
                                VStack(spacing: 6) {
                                    Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 48, height: 48)
                                    Text(app.displayName)
                                        .font(.caption2)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(tr("使用 Metal HUD 启动", "Launch with Metal HUD")) { model.launchRecordedAppWithMetalHUD(app.path) }
                                Button(tr("从列表中移除", "Remove"), role: .destructive) { model.removeRecentMetalHUDApp(app) }
                            }
                        }
                    }
                }
            }
        }
    }

    private func presetButton(_ title: String, _ preset: MetalHUDPreset) -> some View {
        let isSelected = model.currentMetalHUDPreset() == preset
        return Button(title) {
            model.applyMetalHUDPreset(preset)
        }
        .controlSize(.small)
        .buttonStyle(.bordered)
        .tint(isSelected ? GamingTheme.cyberCyan : nil)
    }
}
