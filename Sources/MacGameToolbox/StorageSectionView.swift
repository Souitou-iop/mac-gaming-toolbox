import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import MacGameToolboxCore
#endif

public struct StorageSectionView: View {
    @EnvironmentObject private var model: AppModel

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            GamingSectionHeader(
                icon: "externaldrive.fill",
                title: tr("存储与磁盘管理", "Storage & Volume Management"),
                subtitle: tr("自定义外接磁盘挂载路径节省内置存储，一键清理无用游戏与系统缓存", "Customize mount paths for external storage and purge game caches with safety filters"),
                accentColor: GamingTheme.cyberCyan
            )

            // Disk Custom Mount Card
            diskMountCard

            // Cache & Log Purge Card
            cachePurgeCard
        }
    }

    // MARK: - Disk Mount Card

    private var diskMountCard: some View {
        GamingGlassCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(GamingTheme.cyberCyan.opacity(0.16))
                            .frame(width: 44, height: 44)
                        Image(systemName: "externaldrive.fill.badge.plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(GamingTheme.cyberCyan)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(tr("将磁盘挂载到指定路径", "Mount Disks at Custom Paths"))
                                .font(.headline)
                            if !model.configuration.diskPresets.isEmpty {
                                Text(tr("\(model.configuration.diskPresets.count) 个预设", "\(model.configuration.diskPresets.count) presets"))
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(GamingTheme.cyberCyan.opacity(0.12), in: Capsule())
                                    .foregroundStyle(GamingTheme.cyberCyan)
                            }
                        }
                        Text(tr("自定义外接磁盘的挂载点（如游戏资源目录），将大体积游戏无缝重定向至外置固态硬盘以释放内置空间",
                                "Mount external SSDs to custom game data paths to save precious internal disk space."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider().opacity(0.3)

                HStack(spacing: 12) {
                    Button {
                        model.loadDisks()
                    } label: {
                        Label(tr("管理磁盘与挂载点", "Manage Volumes"), systemImage: "slider.horizontal.2.square")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(GamingTheme.cyberCyan)
                    .controlSize(.regular)

                    Button {
                        model.restorePreviousMounts()
                    } label: {
                        Label(tr("恢复上次挂载", "Restore Last Mount"), systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                    Spacer()

                    Toggle(tr("启动时自动恢复挂载", "Auto restore on launch"), isOn: Binding(
                        get: { model.configuration.automaticallyRestoreMountsOnLaunch },
                        set: { model.setAutomaticallyRestoreMountsOnLaunch($0) }
                    ))
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Cache Purge Card

    private var cachePurgeCard: some View {
        GamingGlassCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(GamingTheme.coralRed.opacity(0.16))
                            .frame(width: 44, height: 44)
                        Image(systemName: "trash.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(GamingTheme.coralRed)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(tr("缓存与日志一键清理", "Cache & Log Purge"))
                            .font(.headline)
                        Text(tr("安全扫描并清理冗余的用户缓存和系统日志。开启敏感文件保护时不会影响登录状态与重要存档。",
                                "Safely scans and clears redundant user caches and logs without losing save files."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider().opacity(0.3)

                HStack(spacing: 12) {
                    Button(role: .destructive) {
                        model.prepareCacheScan()
                    } label: {
                        Label(tr("一键安全清理", "Scan & Clean Now"), systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(GamingTheme.coralRed)
                    .controlSize(.regular)

                    Spacer()

                    Toggle(tr("排除敏感文件 (推荐)", "Exclude sensitive files (Recommended)"), isOn: Binding(
                        get: { model.configuration.excludesSensitiveCacheFiles },
                        set: { model.setExcludesSensitiveCacheFiles($0) }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
            }
        }
    }
}
