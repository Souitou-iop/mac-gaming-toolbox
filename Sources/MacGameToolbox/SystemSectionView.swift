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
                subtitle: tr("反作弊主机名伪装、壁纸定制、系统诊断与教程", "Anti-cheat environment spoofing, custom wallpaper themes, and diagnostics"),
                accentColor: .purple
            )

            // SteamDeck Spoofing Box
            steamDeckSpoofBox

            // Wallpaper Box
            wallpaperThemeBox

            // Utilities & Info Grid
            HStack(spacing: 16) {
                tutorialBox
                changelogBox
            }

            // Diagnostics & Repair Box
            diagnosticsBox
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

    // MARK: - Wallpaper Box

    private var wallpaperThemeBox: some View {
        GroupBox(label: Label(tr("自定义壁纸", "Wallpaper Customization"), systemImage: "photo.fill.on.rectangle.fill").font(.headline)) {
            VStack(alignment: .leading, spacing: 12) {
                Text(tr("导入您喜欢的游戏壁纸作为工具箱背景，界面将自动呈现原生毛玻璃拟态渲染。",
                        "Import custom game wallpapers. The app automatically renders dynamic background vibrancy."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 12) {
                    Button {
                        model.importWallpaper()
                    } label: {
                        Label(
                            model.configuration.customWallpaperPath == nil ? tr("导入壁纸图片…", "Import Wallpaper…") : tr("更换壁纸…", "Change Wallpaper…"),
                            systemImage: "square.and.arrow.down.fill"
                        )
                    }
                    .buttonStyle(.borderedProminent)
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
