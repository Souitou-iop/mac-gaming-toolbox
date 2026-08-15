import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import MacGameToolboxCore
#endif

public struct GameBoostSectionView: View {
    @EnvironmentObject private var model: AppModel

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            GamingSectionHeader(
                icon: "bolt.fill",
                title: tr("游戏加速与启动优化", "Game Boost & Launch Assistant"),
                subtitle: tr("优化 Windows 转译游戏调度优先级，辅助绕过特定启动网络校验", "Optimize Wine process scheduling priority and assist launcher network validation"),
                accentColor: GamingTheme.cyberCyan
            )

            // CrossOver & Wine Priority Boost Card
            winePriorityBoostCard

            // HoYoGames Launch Assistant Card
            hoYoAssistantCard
        }
    }

    // MARK: - CrossOver & Wine Priority Boost Card

    private var winePriorityBoostCard: some View {
        GamingGlassCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(GamingTheme.cyberCyan.opacity(0.16))
                            .frame(width: 44, height: 44)
                        Image(systemName: "bolt.badge.clock.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(GamingTheme.cyberCyan)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(tr("提高 CrossOver 与 Wine 进程优先级", "Increase CrossOver & Wine Priority"))
                            .font(.headline)
                        Text(tr("将 Wine / GPTK 及其子游戏进程调度优先级提升至最高（Renice -20），改善卡顿与掉帧",
                                "Elevate scheduling priority for Wine/GPTK game processes to maximum (Renice -20)."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider().opacity(0.3)

                HStack(spacing: 12) {
                    Button {
                        model.increaseCrossOverPriority()
                    } label: {
                        Label(tr("自动检测并优化", "Auto Detect & Optimize"), systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(GamingTheme.cyberCyan)
                    .controlSize(.regular)

                    Button {
                        model.loadProcessesForManualSelection()
                    } label: {
                        Label(tr("手动选择进程", "Manual Selection"), systemImage: "list.bullet")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                    Spacer()
                }
            }
        }
    }

    // MARK: - HoYoGames Launch Assistant Card

    private var hoYoAssistantCard: some View {
        GamingGlassCard(isActive: model.isHoYoAssistantRunning, padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(model.isHoYoAssistantRunning ? GamingTheme.amberWarning.opacity(0.2) : Color.white.opacity(0.06))
                            .frame(width: 44, height: 44)
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(model.isHoYoAssistantRunning ? GamingTheme.amberWarning : GamingTheme.electricViolet)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(tr("HoYoGames 启动辅助", "HoYoGames Launch Assistant"))
                                .font(.headline)
                            LiveStatusBadge(model.isHoYoAssistantRunning ? .warning : .idle, title: model.isHoYoAssistantRunning ? tr("辅助中", "Active") : tr("就绪", "Ready"))
                        }
                        Text(tr("点击“开始运行”后在倒计时内打开游戏，工具箱将临时代理域名并在启动后自动恢复 hosts",
                                "Click Start, then open the game within the countdown. Hosts are automatically restored afterwards."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider().opacity(0.3)

                HStack(spacing: 14) {
                    if model.isHoYoAssistantRunning {
                        Button(role: .destructive) {
                            model.cancelHoYoAssistant()
                        } label: {
                            Label(tr("取消并立即恢复 hosts", "Cancel & Restore Hosts"), systemImage: "xmark.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(GamingTheme.coralRed)
                        .controlSize(.regular)
                    } else {
                        Button {
                            model.startHoYoAssistant()
                        } label: {
                            Label(tr("开始运行", "Start Assistant"), systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(GamingTheme.electricViolet)
                        .controlSize(.regular)
                    }

                    HStack(spacing: 8) {
                        Text(tr("等待超时：", "Wait Time:"))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Picker("", selection: Binding(
                            get: { model.configuration.hoYoWaitSeconds },
                            set: { model.setHoYoWaitSeconds($0) }
                        )) {
                            ForEach([10, 15, 20], id: \.self) { sec in
                                Text("\(sec) \(tr("秒", "sec"))").tag(sec)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }

                    Spacer()
                }
            }
        }
    }
}
