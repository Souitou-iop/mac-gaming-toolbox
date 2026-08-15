import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import MacGameToolboxCore
#endif

public struct StorageSectionView: View {
    @EnvironmentObject private var model: AppModel

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            GamingSectionHeader(
                icon: "externaldrive.fill",
                title: tr("存储与存档管理", "Storage & Save Game Management"),
                subtitle: tr("外接磁盘挂载、Windows 游戏存档一键备份与缓存清理", "External volume mounts, Windows game save backup, and cache cleaner"),
                accentColor: .cyan
            )

            // Game Save & Bottle Manager Box (Direction 4)
            gameSaveManagerBox

            // Disk Custom Mount Box
            diskMountBox

            // Cache & Log Purge Box
            cachePurgeBox
        }
        .onAppear {
            if model.discoveredBottles.isEmpty {
                model.scanBottlesAndSaves()
            }
        }
    }

    // MARK: - Game Save & Bottle Manager Box (Direction 4)

    private var gameSaveManagerBox: some View {
        GroupBox(label:
            HStack(spacing: 8) {
                Label(tr("Windows 游戏存档与容器备份", "Windows Game Save & Bottle Manager"), systemImage: "archivebox.fill")
                    .font(.headline)
                    .foregroundStyle(.cyan)
                if !model.bottleGameSaves.isEmpty {
                    Text(tr("\(model.bottleGameSaves.count) 个存档", "\(model.bottleGameSaves.count) saves found"))
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.12), in: Capsule())
                        .foregroundStyle(.cyan)
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(tr("自动扫描 CrossOver、Whisky 及 Wine 容器中的深层 Windows 游戏存档目录（AppData、Saved Games、My Games），支持一键定位与打包备份。",
                        "Scans AppData, Saved Games, and My Games directories in CrossOver and Whisky bottles for 1-click reveal and zip backups."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                // Bottle Selector & Refresh Controls
                HStack(spacing: 12) {
                    if !model.discoveredBottles.isEmpty {
                        Picker(tr("选择容器：", "Bottle:"), selection: Binding(
                            get: { model.selectedBottleID ?? model.discoveredBottles.first?.id ?? "" },
                            set: { model.selectBottle(id: $0) }
                        )) {
                            ForEach(model.discoveredBottles) { bottle in
                                Label("\(bottle.name) (\(bottle.type.rawValue))", systemImage: bottle.type.iconName)
                                    .tag(bottle.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 260)
                    }

                    Button {
                        model.scanBottlesAndSaves()
                    } label: {
                        Label(
                            model.isScanningSaves ? tr("扫描中…", "Scanning…") : tr("重新扫描存档", "Rescan Saves"),
                            systemImage: "arrow.clockwise"
                        )
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .disabled(model.isScanningSaves)

                    Spacer()
                }

                // Discovered Saves List
                if model.discoveredBottles.isEmpty && !model.isScanningSaves {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text(tr("未在默认路径检测到 CrossOver 或 Whisky 容器。如果您在其他路径自建了 Wine Prefix，可随时在此管理。",
                                "No bottles found in default paths. Custom Wine prefixes can also be backed up here."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                } else if model.bottleGameSaves.isEmpty && !model.isScanningSaves {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal")
                            .foregroundStyle(.secondary)
                        Text(tr("当前容器暂无已识别的游戏存档目录（首次运行游戏并产生存档后将自动显示）。",
                                "No game save folders found in this bottle yet."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                } else {
                    VStack(spacing: 6) {
                        ForEach(model.bottleGameSaves.prefix(6)) { (save: GameSaveLocation) in
                            HStack(spacing: 10) {
                                Image(systemName: "doc.zipper")
                                    .font(.subheadline)
                                    .foregroundStyle(.cyan)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(save.gameName)
                                        .font(.subheadline.weight(.medium))
                                    Text("\(save.category) · 大小: \(save.sizeFormatted)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    model.revealSaveLocationInFinder(save)
                                } label: {
                                    Label(tr("定位", "Reveal"), systemImage: "folder")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                Button {
                                    model.exportSaveBackup(save)
                                } label: {
                                    Label(tr("备份为 Zip…", "Backup Zip…"), systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                            .padding(8)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
            .padding(6)
        }
    }

    // MARK: - Disk Mount Box

    private var diskMountBox: some View {
        GroupBox(label:
            HStack(spacing: 8) {
                Label(tr("将磁盘挂载到指定路径", "Mount Disks at Custom Paths"), systemImage: "externaldrive.fill.badge.plus")
                    .font(.headline)
                if !model.configuration.diskPresets.isEmpty {
                    Text(tr("\(model.configuration.diskPresets.count) 个预设", "\(model.configuration.diskPresets.count) presets"))
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.12), in: Capsule())
                        .foregroundStyle(.cyan)
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(tr("自定义外接磁盘的挂载点（如游戏资源目录），将大体积游戏无缝重定向至外置固态硬盘以释放内置空间。",
                        "Mount external SSDs to custom game data paths to save precious internal disk space."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 12) {
                    Button {
                        model.loadDisks()
                    } label: {
                        Label(tr("管理磁盘与挂载点…", "Manage Volumes…"), systemImage: "slider.horizontal.2.square")
                    }
                    .buttonStyle(.borderedProminent)
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
                }
            }
            .padding(6)
        }
    }

    // MARK: - Cache Purge Box

    private var cachePurgeBox: some View {
        GroupBox(label: Label(tr("缓存与日志一键清理", "Cache & Log Purge"), systemImage: "trash.fill").font(.headline)) {
            VStack(alignment: .leading, spacing: 12) {
                Text(tr("安全扫描并清理冗余的用户缓存和系统日志。开启敏感文件保护时不会影响登录状态与重要存档。",
                        "Safely scans and clears redundant user caches and logs without losing save files."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 12) {
                    Button(role: .destructive) {
                        model.prepareCacheScan()
                    } label: {
                        Label(tr("扫描并清理缓存…", "Scan & Clear Caches…"), systemImage: "trash")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.regular)

                    Spacer()

                    Toggle(tr("敏感文件排除保护", "Protect sensitive files"), isOn: Binding(
                        get: { model.configuration.excludesSensitiveCacheFiles },
                        set: { model.setExcludesSensitiveCacheFiles($0) }
                    ))
                    .toggleStyle(.checkbox)
                    .font(.caption)
                }
            }
            .padding(6)
        }
    }
}
