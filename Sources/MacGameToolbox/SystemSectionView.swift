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
        VStack(alignment: .leading, spacing: 20) {
            // Header
            GamingSectionHeader(
                icon: "gearshape.2.fill",
                title: tr("系统工具与个性化", "System Tools & Preferences"),
                subtitle: tr("反作弊环境伪装、自定义壁纸主题、系统诊断与教程总览", "Anti-cheat environment spoofing, custom wallpaper themes, and diagnostics"),
                accentColor: GamingTheme.electricViolet
            )

            // SteamDeck Spoofing Card
            steamDeckSpoofCard

            // Wallpaper & Visuals Card
            wallpaperThemeCard

            // Utilities & Info Grid
            HStack(spacing: 16) {
                tutorialCard
                changelogCard
            }

            // Diagnostics & Repair
            diagnosticsCard
        }
    }

    // MARK: - SteamDeck Spoofing Card

    private var steamDeckSpoofCard: some View {
        GamingGlassCard(isActive: isSteamDeckActive, padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isSteamDeckActive ? GamingTheme.electricViolet.opacity(0.2) : Color.white.opacity(0.06))
                            .frame(width: 44, height: 44)
                        Image(systemName: "rectangle.2.swap")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(isSteamDeckActive ? GamingTheme.electricViolet : .secondary)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(tr("切换到 SteamDeck 主机名模式", "SteamDeck Mode Spoofing"))
                                .font(.headline)
                            LiveStatusBadge(isSteamDeckActive ? .active : .idle, title: isSteamDeckActive ? tr("已伪装为 SteamDeck", "Spoofed as SteamDeck") : tr("原生 Mac 主机名", "Native Mac Hostname"))
                        }
                        Text(tr("部分游戏的反作弊系统对 SteamDeck 开放后门，将 Mac 主机名临时伪装为 steamdeck 可绕过限制直接进入游戏",
                                "Some anti-cheat systems whitelist SteamDeck. Temporarily spoofing macOS hostname to 'steamdeck' allows games to run."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider().opacity(0.3)

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
                    .tint(isSteamDeckActive ? GamingTheme.coralRed : GamingTheme.electricViolet)
                    .controlSize(.regular)

                    Spacer()

                    if let backup = model.configuration.hostnameBackup {
                        Text(tr("原始名称：\(backup.computerName)", "Original: \(backup.computerName)"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Wallpaper & Visuals Card

    private var wallpaperThemeCard: some View {
        GamingGlassCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(GamingTheme.neonEmerald.opacity(0.16))
                            .frame(width: 44, height: 44)
                        Image(systemName: "photo.fill.on.rectangle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(GamingTheme.neonEmerald)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(tr("自定义壁纸与 Liquid Glass 拟态", "Wallpaper & Liquid Glass Theme"))
                            .font(.headline)
                        Text(tr("导入您喜欢的游戏壁纸作为工具箱背景，界面将自动开启原生景深毛玻璃拟态渲染",
                                "Import custom game wallpapers. The app automatically renders dynamic Liquid Glass vibrancy."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider().opacity(0.3)

                HStack(spacing: 12) {
                    Button {
                        model.importWallpaper()
                    } label: {
                        Label(
                            model.configuration.customWallpaperPath == nil ? tr("导入壁纸图片", "Import Wallpaper") : tr("更换壁纸", "Change Wallpaper"),
                            systemImage: "square.and.arrow.down.fill"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(GamingTheme.neonEmerald)
                    .controlSize(.regular)

                    if model.configuration.customWallpaperPath != nil {
                        Button(role: .destructive) {
                            model.resetWallpaper()
                        } label: {
                            Label(tr("恢复默认背景", "Reset to Default"), systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Tutorial & Changelog Cards

    private var tutorialCard: some View {
        GamingGlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "book.pages.fill")
                        .font(.title2)
                        .foregroundStyle(GamingTheme.cyberCyan)
                    Text(tr("教程总导航", "Tutorial Hub"))
                        .font(.headline)
                }
                Text(tr("Mac 游戏运行、Wine 容器配置、GPTK 补丁教程", "Guides for Mac gaming, Wine bottles, and GPTK."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Button(tr("打开教程导航", "Open Hub")) {
                    model.showingTutorials = true
                }
                .controlSize(.small)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var changelogCard: some View {
        GamingGlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title2)
                        .foregroundStyle(GamingTheme.electricViolet)
                    Text(tr("更新日志", "Changelog"))
                        .font(.headline)
                }
                Text(tr("查看最新版本更新历史与功能改进记录", "View recent release changes and feature enhancements."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Button(tr("查看更新记录", "View Changelog")) {
                    model.showingChangelog = true
                }
                .controlSize(.small)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Diagnostics & Repair

    private var diagnosticsCard: some View {
        GamingGlassCard(cornerRadius: 14, padding: 14) {
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

                Button(tr("导出诊断日志", "Export Diagnostics")) {
                    model.requestDiagnosticsExport()
                }
                .controlSize(.small)
            }
        }
    }
}
