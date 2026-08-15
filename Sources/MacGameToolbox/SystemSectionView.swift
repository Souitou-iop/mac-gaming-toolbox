import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import MacGameToolboxCore
#endif

public struct SystemSectionView: View {
    @EnvironmentObject private var model: AppModel

    private var isSteamDeckActive: Bool {
        model.configuration.hostnameBackup != nil
    }

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            GamingSectionHeader(
                icon: "gearshape.2.fill",
                title: tr("系统工具与偏好设置", "System Tools & Preferences"),
                subtitle: tr("软件服务与权限状态体检、反作弊主机名伪装与系统诊断", "Service & permission health diagnostics, anti-cheat environment spoofing, and system tools"),
                accentColor: .purple
            )

            // Service & Permission Health Inspector Box
            systemHealthBox

            // SteamDeck Spoofing Box
            steamDeckSpoofBox

            // Utilities & Info Grid
            HStack(spacing: 16) {
                tutorialBox
                changelogBox
            }

            // Diagnostics & Repair Box
            diagnosticsBox
        }
        .onAppear {
            if model.healthReport == nil {
                model.checkSystemHealth()
            }
        }
    }

    // MARK: - Service & Permission Health Box

    private var systemHealthBox: some View {
        let isHealthy = model.healthReport?.allHealthy ?? false
        let hasLegacy = !(model.healthReport?.legacyHelpersFound.isEmpty ?? true)

        return GroupBox(label:
            HStack(spacing: 8) {
                Label(tr("软件服务与系统权限检测", "Software Service & Permission Health"), systemImage: "shield.checkerboard")
                    .font(.headline)
                    .foregroundStyle(.purple)
                LiveStatusBadge(
                    isHealthy ? .active : (hasLegacy ? .warning : .idle),
                    title: isHealthy ? tr("全部正常", "All Healthy") : (hasLegacy ? tr("发现历史残留", "Legacy Residuals") : tr("就绪", "Ready"))
                )
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(tr("检测特权辅助服务 (XPC 通信)、系统后台运行权限与 Metal HUD 注入环境，支持一键体检与历史旧版本残留清理。",
                        "Inspects privileged helper XPC status, background items permission, and Metal HUD injection environment."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                // Health Items List
                if let report = model.healthReport {
                    VStack(spacing: 8) {
                        ForEach(report.items) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: item.status.iconName)
                                    .foregroundStyle(item.status == .healthy ? .green : (item.status == .warning ? .orange : .red))
                                    .font(.subheadline)
                                    .padding(.top, 1)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tr(item.nameZh, item.nameEn))
                                        .font(.caption.bold())
                                    Text(tr(item.detailZh, item.detailEn))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(6)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }

                    // Legacy Helper Warning Banner
                    if !report.legacyHelpersFound.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(tr("检测到历史旧版本辅助服务残留", "Legacy Helper Residuals Detected"))
                                    .font(.caption.bold())
                                Text(tr("发现历史服务：\(report.legacyHelpersFound.joined(separator: ", "))。建议点击下方一键清理。",
                                        "Found: \(report.legacyHelpersFound.joined(separator: ", ")). Click cleanup below."))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                    }
                } else {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(tr("正在进行服务健康诊断…", "Inspecting system health…"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Divider()

                // Action Controls
                HStack(spacing: 12) {
                    Button {
                        model.cleanAllLegacyHelpersAndRepair()
                    } label: {
                        Label(tr("一键体检与自动修复", "Run Full Diagnostic & Auto Repair"), systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .controlSize(.regular)

                    Button {
                        model.openBackgroundSettings()
                    } label: {
                        Label(tr("打开系统后台设置…", "Open Login Items…"), systemImage: "gearshape")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                    Button {
                        model.checkSystemHealth()
                    } label: {
                        Label(tr("刷新", "Refresh"), systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .disabled(model.isCheckingHealth)

                    Spacer()
                }
            }
            .padding(6)
        }
    }

    // MARK: - SteamDeck Spoofing Box

    private var steamDeckSpoofBox: some View {
        GroupBox(label:
            HStack(spacing: 8) {
                Label(tr("切换到 SteamDeck 主机名模式", "SteamDeck Mode Spoofing"), systemImage: "rectangle.2.swap")
                    .font(.headline)
                LiveStatusBadge(isSteamDeckActive ? .active : .idle, title: isSteamDeckActive ? tr("已伪装为 SteamDeck", "Spoofed as SteamDeck") : tr("原生 Mac 主机名", "Native Mac Hostname"))
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(tr("部分游戏的反作弊系统对 SteamDeck 开放后门，将 Mac 主机名临时伪装为 steamdeck 可绕过限制直接进入游戏。",
                        "Some anti-cheat systems whitelist SteamDeck. Temporarily spoofing macOS hostname to 'steamdeck' allows games to run."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                HStack {
                    Button {
                        model.toggleSteamDeck()
                    } label: {
                        Label(
                            isSteamDeckActive ? tr("恢复为原始主机名", "Restore Original Hostname") : tr("一键开启 SteamDeck 伪装", "Enable SteamDeck Spoofing"),
                            systemImage: isSteamDeckActive ? "arrow.counterclockwise" : "shield.lefthalf.filled"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isSteamDeckActive ? .red : .purple)
                    .controlSize(.regular)

                    Spacer()

                    if let backup = model.configuration.hostnameBackup {
                        Text(tr("原始名称：\(backup.computerName)", "Original: \(backup.computerName)"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(6)
        }
    }

    // MARK: - Tutorial & Changelog Boxes

    private var tutorialBox: some View {
        GroupBox(label: Label(tr("教程总导航", "Tutorial Hub"), systemImage: "book.pages.fill").font(.headline)) {
            VStack(alignment: .leading, spacing: 10) {
                Text(tr("Mac 游戏运行、Wine 容器配置、GPTK 补丁教程", "Guides for Mac gaming, Wine bottles, and GPTK."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Button(tr("打开教程导航…", "Open Hub…")) {
                    model.showingTutorials = true
                }
                .controlSize(.small)
            }
            .padding(4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var changelogBox: some View {
        GroupBox(label: Label(tr("更新日志", "Changelog"), systemImage: "clock.arrow.circlepath").font(.headline)) {
            VStack(alignment: .leading, spacing: 10) {
                Text(tr("查看最新版本更新历史与功能改进记录", "View recent release changes and feature enhancements."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Button(tr("查看更新记录…", "View Changelog…")) {
                    model.showingChangelog = true
                }
                .controlSize(.small)
            }
            .padding(4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Diagnostics & Repair Box

    private var diagnosticsBox: some View {
        GroupBox {
            HStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)

                Text(tr("遇到权限或执行异常？", "Encountered issues?"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(tr("修复核心功能", "Repair Core")) {
                    model.repairCoreFeatures()
                }
                .controlSize(.small)

                Button(tr("导出诊断日志…", "Export Diagnostics…")) {
                    model.requestDiagnosticsExport()
                }
                .controlSize(.small)
            }
            .padding(4)
        }
    }
}
