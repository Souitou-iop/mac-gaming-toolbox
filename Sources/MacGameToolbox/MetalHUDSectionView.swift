import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import MacGameToolboxCore
#endif

public struct MetalHUDSectionView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedTab: TunerTab = .appearance
    @State private var showingProcessNotice = true

    enum TunerTab: String, CaseIterable, Identifiable {
        case appearance
        case metrics
        case advanced

        var id: String { rawValue }

        var title: String {
            switch self {
            case .appearance: return tr("外观与布局", "Appearance & Layout")
            case .metrics: return tr("监控指标", "Metrics")
            case .advanced: return tr("日志与诊断", "Logging & Diagnostics")
            }
        }
    }

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            GamingSectionHeader(
                icon: "chart.xyaxis.line",
                title: tr("Metal HUD 性能监视器", "Metal HUD Performance Monitor"),
                subtitle: tr("实时呈现 Metal 游戏渲染帧率、GPU/CPU 开销及管线状态", "Overlay real-time FPS, GPU/CPU execution time, and pipeline stats in Metal games."),
                accentColor: .green
            )

            // Master Toggle & Actions Card
            masterControlCard

            // Interference notice card
            if showingProcessNotice {
                interferenceNoticeCard
            }

            // Tuning Settings Box
            tunerSettingsBox

            // Recent Apps Grid
            if !model.configuration.recentMetalHUDApps.isEmpty {
                recentAppsBox
            }
        }
    }

    // MARK: - Master Control Card

    private var masterControlCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { model.metalHUDEnabled },
                        set: { model.setMetalHUD($0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Text(tr("全局启用 Metal HUD", "Enable Metal HUD Globally"))
                                    .font(.headline)
                                LiveStatusBadge(model.metalHUDEnabled ? .active : .idle)
                            }
                            Text(tr("写入系统 MetalForceHudEnabled 键。开启后所有基于 Metal 的 3D 游戏将自动呈现 HUD 仪表盘。",
                                    "Writes to MetalForceHudEnabled. Automatically displays the HUD overlay in Metal 3D games."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                }

                Divider()

                HStack(spacing: 10) {
                    Button {
                        model.launchAppWithMetalHUD()
                    } label: {
                        Label(tr("注入启动单个 App…", "Launch App with HUD…"), systemImage: "plus.app.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        model.openMetalHUDProcessManager()
                    } label: {
                        Label(tr("排查冲突进程…", "Check Interfering Processes…"), systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button(tr("重置默认配置", "Reset Settings"), role: .destructive) {
                        model.resetMetalHUDOptions()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            }
            .padding(6)
        }
    }

    // MARK: - Interference Notice Card

    private var interferenceNoticeCard: some View {
        GroupBox {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.body)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tr("温馨提示：若开启后游戏内未出现 HUD", "Notice: If HUD does not appear in game"))
                        .font(.subheadline.bold())
                    Text(tr("1. 启动器（Steam/CrossOver/Whisky）在开启前已运行，需在下方点击“排查冲突进程”重启启动器；\n2. 纯 2D/GDI 渲染的 Windows Galgame 无法挂载 Metal 3D 钩子，DirectX 11/12 3D 游戏可正常显示。",
                            "1. If game launchers were running before enabling, click 'Check Interfering Processes' to restart them;\n2. 2D/GDI Windows apps do not hook into Metal 3D, while DirectX 11/12 3D games work out of the box."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    withAnimation { showingProcessNotice = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(4)
        }
    }

    // MARK: - Tuner Settings Box

    private var tunerSettingsBox: some View {
        GroupBox(label: Text(tr("HUD 参数调优", "HUD Tuning Options")).font(.headline)) {
            VStack(alignment: .leading, spacing: 14) {
                // Segmented Tab Picker
                Picker("", selection: $selectedTab) {
                    ForEach(TunerTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, 4)

                Divider()

                switch selectedTab {
                case .appearance:
                    appearanceTabContent
                case .metrics:
                    metricsTabContent
                case .advanced:
                    advancedTabContent
                }
            }
            .padding(6)
        }
    }

    // MARK: - Appearance Tab

    private var appearanceTabContent: some View {
        VStack(spacing: 12) {
            // Presets
            LabeledContent(tr("快捷预设", "Presets")) {
                HStack(spacing: 8) {
                    presetButton(tr("精简", "Minimal"), .minimal)
                    presetButton(tr("均衡 (默认)", "Balanced"), .balanced)
                    presetButton(tr("完整", "Complex"), .complex)
                    Spacer()
                }
            }

            Divider()

            // Scale Slider
            LabeledContent(tr("缩放比例", "Scale")) {
                HStack(spacing: 12) {
                    Slider(
                        value: Binding(
                            get: { model.configuration.metalHUDOptions.scale },
                            set: { var opts = model.configuration.metalHUDOptions; opts.scale = $0; model.updateMetalHUDOptions(opts) }
                        ),
                        in: 0.1...1.0,
                        step: 0.05
                    )
                    .frame(maxWidth: 240)

                    Text(String(format: "%.0f%%", model.configuration.metalHUDOptions.scale * 100))
                        .font(.callout.monospacedDigit())
                        .frame(width: 44, alignment: .trailing)
                }
            }

            // Opacity Slider
            LabeledContent(tr("不透明度", "Opacity")) {
                HStack(spacing: 12) {
                    Slider(
                        value: Binding(
                            get: { model.configuration.metalHUDOptions.opacity },
                            set: { var opts = model.configuration.metalHUDOptions; opts.opacity = $0; model.updateMetalHUDOptions(opts) }
                        ),
                        in: 0.0...1.0,
                        step: 0.05
                    )
                    .frame(maxWidth: 240)

                    Text(String(format: "%.0f%%", model.configuration.metalHUDOptions.opacity * 100))
                        .font(.callout.monospacedDigit())
                        .frame(width: 44, alignment: .trailing)
                }
            }

            // Alignment Picker
            LabeledContent(tr("屏幕方位", "Alignment")) {
                Picker("", selection: Binding(
                    get: { model.configuration.metalHUDOptions.alignment },
                    set: { var opts = model.configuration.metalHUDOptions; opts.alignment = $0; model.updateMetalHUDOptions(opts) }
                )) {
                    Text(tr("右上角 (默认)", "Top Right")).tag("topright")
                    Text(tr("左上角", "Top Left")).tag("topleft")
                    Text(tr("右下角", "Bottom Right")).tag("bottomright")
                    Text(tr("左下角", "Bottom Left")).tag("bottomleft")
                }
                .frame(maxWidth: 240)
            }
        }
    }

    private func presetButton(_ title: String, _ preset: MetalHUDPreset) -> some View {
        let isSelected = model.currentMetalHUDPreset() == preset
        return Button(title) {
            model.applyMetalHUDPreset(preset)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .accentColor : nil)
        .controlSize(.small)
    }

    // MARK: - Metrics Tab

    private var metricsTabContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tr("勾选需要显示的 HUD 指标项：", "Select items to display in HUD:"))
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 8)], spacing: 8) {
                ForEach(MetalHUDElement.allElements, id: \.raw) { (element: MetalHUDElement) in
                    let isChecked = model.configuration.metalHUDOptions.elements.contains(element.raw)
                    Toggle(isOn: Binding(
                        get: { isChecked },
                        set: { checked in
                            var opts = model.configuration.metalHUDOptions
                            if checked {
                                if !opts.elements.contains(element.raw) {
                                    opts.elements.append(element.raw)
                                }
                            } else {
                                opts.elements.removeAll { $0 == element.raw }
                            }
                            model.updateMetalHUDOptions(opts)
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(tr(element.zh, element.en))
                                .font(.subheadline)
                            Text(element.raw)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .toggleStyle(.checkbox)
                    .padding(6)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
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
                .controlSize(.regular)
            }
            .padding(.top, 4)
        }
        .font(.subheadline)
    }

    // MARK: - Recent Apps Box

    private var recentAppsBox: some View {
        GroupBox(label: Text(tr("快捷启动游戏", "Quick Launch Games")).font(.headline)) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(model.configuration.recentMetalHUDApps) { app in
                        recentAppTile(app)
                    }
                }
                .padding(6)
            }
        }
    }

    private func recentAppTile(_ app: RecentMetalHUDApp) -> some View {
        VStack(spacing: 6) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                .resizable()
                .frame(width: 44, height: 44)

            Text(app.displayName)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 90)

            Button(tr("启动", "Launch")) {
                model.launchRecordedAppWithMetalHUD(app.path)
            }
            .controlSize(.small)
            .buttonStyle(.borderedProminent)
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
        .contextMenu {
            Button(tr("移出列表", "Remove from list"), role: .destructive) {
                model.removeRecentMetalHUDApp(app)
            }
        }
    }
}
