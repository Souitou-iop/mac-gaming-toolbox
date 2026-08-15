import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import MacGameToolboxCore
#endif

public struct OverviewSectionView: View {
    @EnvironmentObject private var model: AppModel
    var onNavigateToSection: ((Int) -> Void)?

    private var isSteamDeckActive: Bool {
        model.configuration.hostnameBackup != nil
    }

    public init(onNavigateToSection: ((Int) -> Void)? = nil) {
        self.onNavigateToSection = onNavigateToSection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Live Stats Hero Strip
            liveStatsStrip

            // Quick Boost Cards
            VStack(alignment: .leading, spacing: 14) {
                Text(tr("快捷电竞工具箱", "Quick Gaming Actions"))
                    .font(.title3.bold())

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
                icon: "gauge.with.dots.needle.67percent",
                title: tr("Metal HUD 状态", "Metal HUD State"),
                value: model.metalHUDEnabled ? tr("已开启", "ACTIVE") : tr("未开启", "OFF"),
                subtitle: model.metalHUDEnabled ? tr("实时环境已注入", "Env Injected") : tr("点击下方开启", "Click to enable"),
                accentColor: model.metalHUDEnabled ? GamingTheme.neonEmerald : .secondary
            )

            MetricStatCard(
                icon: "externaldrive.fill",
                title: tr("外接游戏磁盘", "Mounted Disks"),
                value: "\(model.configuration.diskPresets.count)",
                subtitle: tr("已配置的挂载预设", "Saved presets"),
                accentColor: GamingTheme.cyberCyan
            )

            MetricStatCard(
                icon: "rectangle.2.swap",
                title: tr("主机名模式", "Hostname Mode"),
                value: isSteamDeckActive ? "SteamDeck" : "Mac Native",
                subtitle: isSteamDeckActive ? tr("反作弊伪装中", "Spoofing active") : tr("原生主机名", "Standard macOS"),
                accentColor: isSteamDeckActive ? GamingTheme.electricViolet : .secondary
            )

            MetricStatCard(
                icon: "gamecontroller.fill",
                title: tr("最近启动记录", "Recent Games"),
                value: "\(model.configuration.recentMetalHUDApps.count)",
                subtitle: tr("快速启动就绪", "Ready to launch"),
                accentColor: GamingTheme.neonEmerald
            )
        }
    }

    // MARK: - Quick Action Cards

    private var quickMetalHUDCard: some View {
        GamingGlassCard(isActive: model.metalHUDEnabled, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(model.metalHUDEnabled ? GamingTheme.neonEmerald.opacity(0.2) : Color.white.opacity(0.06))
                            .frame(width: 36, height: 36)
                        Image(systemName: "gauge.with.dots.needle.67percent")
                            .foregroundStyle(model.metalHUDEnabled ? GamingTheme.neonEmerald : .secondary)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(tr("Metal HUD 性能监视器", "Metal HUD Monitor"))
                            .font(.headline)
                        Text(tr("实时帧率与硬件开销面板", "Real-time FPS & GPU overlay"))
                            .font(.caption2)
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

                HStack(spacing: 8) {
                    Button(tr("调优设置", "Tune Settings")) {
                        onNavigateToSection?(1) // Navigate to Metal HUD tab
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(tr("排查进程", "Processes")) {
                        model.openMetalHUDProcessManager()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    private var quickCrossOverCard: some View {
        GamingGlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(GamingTheme.cyberCyan.opacity(0.18))
                            .frame(width: 36, height: 36)
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(GamingTheme.cyberCyan)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(tr("Wine / CrossOver 优先级", "Wine Game Priority"))
                            .font(.headline)
                        Text(tr("优化调度，减少卡顿掉帧", "Renice -20 for smoother fps"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                HStack(spacing: 8) {
                    Button(tr("一键优化", "Optimize Now")) {
                        model.increaseCrossOverPriority()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(GamingTheme.cyberCyan)
                    .controlSize(.small)

                    Button(tr("更多设置", "Details")) {
                        onNavigateToSection?(2) // Navigate to Game Boost tab
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    private var quickDiskCard: some View {
        GamingGlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(GamingTheme.cyberCyan.opacity(0.18))
                            .frame(width: 36, height: 36)
                        Image(systemName: "externaldrive.fill")
                            .foregroundStyle(GamingTheme.cyberCyan)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(tr("外接磁盘游戏挂载", "Custom Disk Mounts"))
                            .font(.headline)
                        Text(tr("重定向至外置 SSD 释放空间", "Mount to custom game dirs"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                HStack(spacing: 8) {
                    Button(tr("管理磁盘", "Manage Disks")) {
                        model.loadDisks()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(GamingTheme.cyberCyan)
                    .controlSize(.small)

                    Button(tr("恢复挂载", "Restore")) {
                        model.restorePreviousMounts()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    private var quickSteamDeckCard: some View {
        GamingGlassCard(isActive: isSteamDeckActive, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(isSteamDeckActive ? GamingTheme.electricViolet.opacity(0.25) : Color.white.opacity(0.06))
                            .frame(width: 36, height: 36)
                        Image(systemName: "rectangle.2.swap")
                            .foregroundStyle(isSteamDeckActive ? GamingTheme.electricViolet : .secondary)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(tr("SteamDeck 模式伪装", "SteamDeck Mode"))
                            .font(.headline)
                        Text(tr("绕过反作弊限制", "Bypass anti-cheat checks"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                HStack(spacing: 8) {
                    Button(isSteamDeckActive ? tr("恢复主机名", "Restore") : tr("开启伪装", "Enable")) {
                        model.toggleSteamDeck()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isSteamDeckActive ? GamingTheme.coralRed : GamingTheme.electricViolet)
                    .controlSize(.small)

                    Button(tr("详情", "Details")) {
                        onNavigateToSection?(4) // Navigate to System tab
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    private var quickHoYoBanner: some View {
        GamingGlassCard(cornerRadius: 14, padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(GamingTheme.electricViolet)

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
                    .tint(GamingTheme.electricViolet)
                    .controlSize(.small)
                }
            }
        }
    }
}
