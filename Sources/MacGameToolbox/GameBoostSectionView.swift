import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import MacGameToolboxCore
#endif

public struct GameBoostSectionView: View {
    @EnvironmentObject private var model: AppModel

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            GamingSectionHeader(
                icon: "bolt.fill",
                title: tr("游戏加速与启动优化", "Game Boost & Launch Assistant"),
                subtitle: tr("优化 Windows 转译游戏调度优先级，辅助绕过特定启动网络校验", "Optimize Wine process scheduling priority and assist launcher network validation"),
                accentColor: .cyan
            )

            // CrossOver & Wine Priority Boost Box
            winePriorityBoostBox

            // HoYoGames Launch Assistant Box
            hoYoAssistantBox
        }
    }

    // MARK: - CrossOver & Wine Priority Boost Box

    private var winePriorityBoostBox: some View {
        GroupBox(label: Label(tr("提高 CrossOver 与 Wine 进程优先级", "Increase CrossOver & Wine Priority"), systemImage: "bolt.badge.clock.fill").font(.headline)) {
            VStack(alignment: .leading, spacing: 12) {
                Text(tr("将 Wine / GPTK 及其子游戏进程调度优先级提升至最高（Renice -20），使 CPU 核心优先分配算力给游戏主线程，显著改善卡顿与掉帧现象。",
                        "Elevate scheduling priority for Wine/GPTK game processes to maximum (Renice -20) to smooth framerates."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 12) {
                    Button {
                        model.increaseCrossOverPriority()
                    } label: {
                        Label(tr("自动检测并优化 (Renice -20)", "Auto Detect & Optimize"), systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)

                    Button {
                        model.loadProcessesForManualSelection()
                    } label: {
                        Label(tr("手动选择进程…", "Manual Selection…"), systemImage: "list.bullet")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                    Spacer()
                }
            }
            .padding(6)
        }
    }

    // MARK: - HoYoGames Launch Assistant Box

    private var hoYoAssistantBox: some View {
        GroupBox(label:
            HStack(spacing: 8) {
                Label(tr("HoYoGames 启动辅助", "HoYoGames Launch Assistant"), systemImage: "gamecontroller.fill")
                    .font(.headline)
                LiveStatusBadge(model.isHoYoAssistantRunning ? .warning : .idle, title: model.isHoYoAssistantRunning ? tr("辅助中", "Active") : tr("就绪", "Ready"))
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(tr("点击“开始运行”后在倒计时内打开游戏，工具箱将临时代理域名并在启动后自动恢复 hosts 文件，避免全局网络受影响。",
                        "Click Start, then open the game within the countdown. Hosts are automatically restored afterwards."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 14) {
                    if model.isHoYoAssistantRunning {
                        Button(role: .destructive) {
                            model.cancelHoYoAssistant()
                        } label: {
                            Label(tr("取消并立即恢复 hosts", "Cancel & Restore Hosts"), systemImage: "xmark.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.regular)
                    } else {
                        Button {
                            model.startHoYoAssistant()
                        } label: {
                            Label(tr("开始运行", "Start Assistant"), systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .controlSize(.regular)
                    }

                    LabeledContent(tr("等待超时：", "Wait Time:")) {
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
            .padding(6)
        }
    }
}
