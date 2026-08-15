import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import MacGameToolboxCore
#endif

public struct OverviewSectionView: View {
    @EnvironmentObject private var model: AppModel
    var onNavigateToSection: ((NavigationCategory) -> Void)?

    private var isSteamDeckActive: Bool {
        model.configuration.hostnameBackup != nil
    }

    public init(onNavigateToSection: ((NavigationCategory) -> Void)? = nil) {
        self.onNavigateToSection = onNavigateToSection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Live Stats Strip
            liveStatsStrip

            // Quick Boost Cards
            VStack(alignment: .leading, spacing: 14) {
                Text(tr("快捷工具箱", "Quick Actions"))
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                    // Metal HUD Card
                    quickMetalHUDCard

                    // CrossOver Priority Card
                    quickCrossOverCard

                    // Disk Mounts Card
                    quickDiskCard

                    // SteamDeck Spoof Card
                    quickSteamDeckCard
                }
            }

            // HoYo Assistant Banner if running or available
            quickHoYoBanner
        }
    }

    // MARK: - Live Stats Strip

    private var liveStatsStrip: some View {
        HStack(spacing: 12) {
            MetricStatCard(
                icon: "chart.xyaxis.line",
                title: tr("Metal HUD 状态", "Metal HUD State"),
                value: model.metalHUDEnabled ? tr("已开启", "ACTIVE") : tr("未开启", "OFF"),
                subtitle: model.metalHUDEnabled ? tr("系统环境已注入", "Env Injected") : tr("点击下方开启", "Tap to enable"),
                accentColor: model.metalHUDEnabled ? .green : .secondary
            )

            MetricStatCard(
                icon: "externaldrive.fill",
                title: tr("外接游戏磁盘", "Mounted Disks"),
                value: "\(model.configuration.diskPresets.count)",
                subtitle: tr("已配置的挂载预设", "Saved presets"),
                accentColor: .cyan
            )

            MetricStatCard(
                icon: "rectangle.2.swap",
                title: tr("主机名模式", "Hostname Mode"),
                value: isSteamDeckActive ? "SteamDeck" : "Mac Native",
                subtitle: isSteamDeckActive ? tr("反作弊伪装中", "Spoofing active") : tr("原生主机名", "Standard macOS"),
                accentColor: isSteamDeckActive ? .purple : .secondary
            )

            MetricStatCard(
                icon: "gamecontroller.fill",
                title: tr("最近启动记录", "Recent Games"),
                value: "\(model.configuration.recentMetalHUDApps.count)",
                subtitle: tr("快速启动就绪", "Ready to launch"),
                accentColor: .green
            )
        }
    }

    // MARK: - Quick Action Boxes

    private var quickMetalHUDCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(tr("Metal HUD 监视器", "Metal HUD Monitor"), systemImage: "chart.xyaxis.line")
                        .font(.headline)
                        .foregroundStyle(model.metalHUDEnabled ? .green : .primary)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { model.metalHUDEnabled },
                        set: { model.setMetalHUD($0) }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }

                Text(tr("实时呈现 FPS、GPU 与 CPU 开销", "Real-time FPS and hardware overlay."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 8) {
                    Button(tr("详细调优…", "Tune Settings…")) {
                        onNavigateToSection?(.metalHUD)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(tr("排查进程…", "Check Processes…")) {
                        model.openMetalHUDProcessManager()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(4)
        }
    }

    private var quickCrossOverCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(tr("Wine 进程优先级", "Wine Priority"), systemImage: "bolt.fill")
                        .font(.headline)
                        .foregroundStyle(.cyan)
                    Spacer()
                }

                Text(tr("调度优先级 Renice -20 减少掉帧卡顿", "Renice -20 for smoother framerate."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 8) {
                    Button(tr("一键优化", "Optimize Now")) {
                        model.increaseCrossOverPriority()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button(tr("更多设置…", "Details…")) {
                        onNavigateToSection?(.gameBoost)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(4)
        }
    }

    private var quickDiskCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(tr("外接磁盘游戏挂载", "Custom Disk Mounts"), systemImage: "externaldrive.fill")
                        .font(.headline)
                        .foregroundStyle(.cyan)
                    Spacer()
                }

                Text(tr("重定向游戏至外置固态释放空间", "Mount SSDs to game directories."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 8) {
                    Button(tr("管理磁盘…", "Manage Disks…")) {
                        model.loadDisks()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button(tr("恢复上次挂载", "Restore")) {
                        model.restorePreviousMounts()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(4)
        }
    }

    private var quickSteamDeckCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(tr("SteamDeck 模式伪装", "SteamDeck Mode"), systemImage: "rectangle.2.swap")
                        .font(.headline)
                        .foregroundStyle(isSteamDeckActive ? .purple : .primary)
                    Spacer()
                }

                Text(tr("将主机名伪装为 steamdeck 绕过反作弊", "Spoof hostname to bypass checks."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 8) {
                    Button(isSteamDeckActive ? tr("恢复主机名", "Restore") : tr("开启伪装", "Enable")) {
                        model.toggleSteamDeck()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isSteamDeckActive ? .red : .purple)
                    .controlSize(.small)

                    Button(tr("详情…", "Details…")) {
                        onNavigateToSection?(.system)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(4)
        }
    }

    private var quickHoYoBanner: some View {
        GroupBox {
            HStack(spacing: 12) {
                Image(systemName: "gamecontroller.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tr("HoYoGames 启动帮助", "HoYoGames Launch Assistant"))
                        .font(.subheadline.bold())
                    Text(tr("临时劫持 hosts 解决启动校验失败，启动后自动恢复网络环境", "Assists launching HoYoGames on Mac by temporarily routing validation endpoints."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if model.isHoYoAssistantRunning {
                    Button(tr("取消运行", "Cancel"), role: .destructive) {
                        model.cancelHoYoAssistant()
                    }
                    .controlSize(.small)
                } else {
                    Button(tr("开始运行", "Start")) {
                        model.startHoYoAssistant()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .controlSize(.small)
                }
            }
            .padding(4)
        }
    }
}
