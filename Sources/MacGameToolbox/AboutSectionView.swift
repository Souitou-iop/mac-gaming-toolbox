import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import MacGameToolboxCore
#endif

public struct AboutSectionView: View {
    @EnvironmentObject private var model: AppModel

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            GamingSectionHeader(
                icon: "info.circle.fill",
                title: tr("关于与致谢", "About & Acknowledgements"),
                subtitle: tr("软件版本信息、原项目引用与开源致谢", "App version, upstream repository references, and acknowledgements"),
                accentColor: .blue
            )

            // App Identity Hero Card
            appHeroBox

            // Upstream Acknowledgements Box
            upstreamAcknowledgementBox

            // Fork Edition Improvements Box
            forkImprovementsBox

            // License & Legal Disclaimer Box
            licenseAndDisclaimerBox
        }
    }

    // MARK: - App Hero Box

    private var appHeroBox: some View {
        GroupBox {
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color.cyan.opacity(0.8), Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 68, height: 68)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(tr("Mac 游戏工具箱", "Mac Gaming Toolbox"))
                            .font(.title2.bold())
                        Text("v3.0.7")
                            .font(.subheadline.monospaced())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12), in: Capsule())
                            .foregroundStyle(.blue)
                    }

                    Text(tr("专为 macOS 打造的原生游戏环境与性能调优辅助工具箱", "Native macOS utility for gaming environment optimization and Metal performance overlays."))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        Text("Architecture:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Apple Silicon (ARM64)")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                    }
                    .padding(.top, 2)
                }

                Spacer()
            }
            .padding(10)
        }
    }

    // MARK: - Upstream Acknowledgements Box

    private var upstreamAcknowledgementBox: some View {
        GroupBox(label: Label(tr("原项目引用与特别致谢", "Original Project & Acknowledgements"), systemImage: "heart.fill").font(.headline).foregroundStyle(.pink)) {
            VStack(alignment: .leading, spacing: 14) {
                Text(tr("本项目由衷感谢原作者及开源社区贡献者的卓越设计与开源分享！",
                        "Special thanks to the original author and open source contributors for this fantastic Mac gaming utility!"))
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Text(tr("原项目作者：", "Original Author:"))
                            .font(.caption.bold())
                            .frame(width: 100, alignment: .leading)
                        Text("我是艾文喵")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        Text(tr("原项目开源库：", "Upstream Repo:"))
                            .font(.caption.bold())
                            .frame(width: 100, alignment: .leading)
                        Link("aiwentongxue/mac-gaming-toolbox", destination: URL(string: "https://github.com/aiwentongxue/mac-gaming-toolbox")!)
                            .font(.caption)
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        Text(tr("原作者主页：", "Author Channels:"))
                            .font(.caption.bold())
                            .frame(width: 100, alignment: .leading)
                        HStack(spacing: 12) {
                            Link("哔哩哔哩 (@我是艾文喵)", destination: URL(string: "https://b23.tv/dV7YBJQ")!)
                            Text("·").foregroundStyle(.secondary)
                            Link("YouTube Channel", destination: URL(string: "https://youtube.com/channel/UC0TgypOLHt2fXboVw34SKVQ")!)
                        }
                        .font(.caption)
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        Text(tr("官方视频教程：", "Video Guides:"))
                            .font(.caption.bold())
                            .frame(width: 100, alignment: .leading)
                        HStack(spacing: 12) {
                            Link(tr("B站重磅发布教程", "Bilibili Release Video"), destination: URL(string: "https://b23.tv/qnJBcbk")!)
                            Text("·").foregroundStyle(.secondary)
                            Link(tr("YouTube 视频教程", "YouTube Video Guide"), destination: URL(string: "https://youtu.be/Y9g4F0_6ipI?si=i3G9dxiXMbk2NSzY")!)
                        }
                        .font(.caption)
                        Spacer()
                    }
                }
            }
            .padding(8)
        }
    }

    // MARK: - Fork Edition Improvements Box

    private var forkImprovementsBox: some View {
        GroupBox(label: Label(tr("本分支版本增强与改进", "Fork Enhancements"), systemImage: "sparkles").font(.headline)) {
            VStack(alignment: .leading, spacing: 8) {
                featureBullet(
                    title: tr("纯原生 macOS 侧边栏架构", "Pure Native Sidebar Architecture"),
                    desc: tr("基于 NavigationSplitView 与标准 GroupBox 控件重构，完美贴合 Apple HIG 人机交互指南。",
                             "Refactored with NavigationSplitView and standard macOS controls conforming to Apple HIG.")
                )
                featureBullet(
                    title: tr("Metal HUD 冲突进程排查器", "Metal HUD Interfering Process Manager"),
                    desc: tr("智能检测 Steam、CrossOver、Wine 服务等先于 HUD 启动的冲突进程，支持用户自主选择一键重启。",
                             "Intelligently scans launchers and Wine services running prior to HUD injection for 1-click clean restart.")
                )
                featureBullet(
                    title: tr("内嵌式调优与纯 ARM64 构建", "Embedded Tuning & Pure ARM64 Build"),
                    desc: tr("告别层层弹窗，HUD 外观缩放与指标直接内嵌主面板，提供纯 Apple Silicon 原生优化。",
                             "Integrated parameter sliders directly in the main panel with optimized Apple Silicon builds.")
                )
            }
            .padding(6)
        }
    }

    private func featureBullet(title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.bold())
                Text(desc)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - License & Legal Disclaimer Box

    private var licenseAndDisclaimerBox: some View {
        GroupBox(label: Label(tr("开源许可与免责声明", "License & Disclaimer"), systemImage: "doc.text.fill").font(.headline)) {
            VStack(alignment: .leading, spacing: 8) {
                Text(tr("开源许可证：GNU General Public License v3.0 (GPL-3.0)", "License: GNU General Public License v3.0 (GPL-3.0)"))
                    .font(.caption.bold())
                Text(tr("本项目为开源辅助工具，并非 Apple、CodeWeavers、HoYoverse 或 Valve 的官方产品。文中出现的所有商标及名称均归其各自所有者拥有。",
                        "This project is an open-source utility and is not affiliated with Apple, CodeWeavers, HoYoverse, or Valve. All trademarks belong to their respective owners."))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(6)
        }
    }
}
