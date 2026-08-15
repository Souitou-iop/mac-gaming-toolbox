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
                subtitle: tr("游戏专注防休眠、Wine 进程算力提速、手柄低延迟与启动辅助", "Gaming focus booster, Wine process priority tuning, controller latency & launch assistance"),
                accentColor: .cyan
            )

            // Gaming Focus & Anti-Sleep Mode Box (Direction 3)
            gamingFocusBox

            // CrossOver & Wine Priority Boost Box
            winePriorityBoostBox

            // Controller Latency & Game Mode Tips Box (Direction 3)
            controllerAndGameModeBox

            // HoYoGames Launch Assistant Box
            hoYoAssistantBox
        }
    }

    // MARK: - Gaming Focus & Anti-Sleep Box

    private var gamingFocusBox: some View {
        GroupBox(label:
            HStack(spacing: 8) {
                Label(tr("游戏专注模式 (防休眠 / 防降频)", "Gaming Focus & Anti-Sleep"), systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                LiveStatusBadge(model.isGamingFocusActive ? .active : .idle, title: model.isGamingFocusActive ? tr("专注中 (已阻止休眠)", "Active (Sleep Blocked)") : tr("未开启", "Inactive"))
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(tr("运行原生 caffeinate 守护进程，在游戏、挂机挂机或编译着色器期间阻止 macOS 自动熄屏、空闲降频和系统休眠，保障最高性能持续输出。",
                        "Runs native caffeinate daemon to prevent display dimming, CPU power throttling, and system sleep during gaming or shader compilation."))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 12) {
                    Button {
                        model.toggleGamingFocus()
                    } label: {
                        Label(
                            model.isGamingFocusActive ? tr("退出游戏专注模式", "Stop Gaming Focus") : tr("开启游戏专注模式", "Start Gaming Focus Mode"),
                            systemImage: model.isGamingFocusActive ? "pause.fill" : "play.fill"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(model.isGamingFocusActive ? .red : .orange)
                    .controlSize(.regular)

                    Spacer()
                }
            }
            .padding(6)
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

    // MARK: - Controller Latency & Game Mode Tips Box

    private var controllerAndGameModeBox: some View {
        GroupBox(label: Label(tr("手柄蓝牙低延迟与着色器科普", "Controller Latency & Shader Optimization"), systemImage: "gamecontroller.fill").font(.headline)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundStyle(.blue)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tr("macOS 游戏模式 (Game Mode) 极速唤醒", "macOS Game Mode Low-Latency Trigger"))
                            .font(.caption.bold())
                        Text(tr("系统“游戏模式”会将 PS5/Xbox 蓝牙手柄与 AirPods 的采样轮询率翻倍，大幅降低无线输入与音频延迟。建议在游戏内开启“全屏独占模式 (Full Screen)”以确保稳定触发 Game Mode。",
                                "macOS Game Mode doubles Bluetooth polling rates for gamepads and AirPods, halving wireless latency. Use Full Screen mode in-game for automatic activation."))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "cpu.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tr("着色器动态编译卡顿 (Shader Stutter) 提示", "Shader Compilation Stutter Notice"))
                            .font(.caption.bold())
                        Text(tr("首次进入新游戏场景时，GPTK 正在后台将 DirectX 着色器动态编译并缓存在 Metal 中，可能出现短暂掉帧，属于正常转译机制。持续游玩 5~10 分钟着色器缓存建立后，游戏帧率将趋于平稳丝滑。",
                                "Entering new scenes triggers DirectX-to-Metal shader compilation. Temporary frame drops are normal and will smooth out after 5-10 minutes of caching."))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
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
                        .controlSize(.regular)
                    }

                    Picker(tr("等待：", "Wait:"), selection: Binding(
                        get: { model.configuration.hoYoWaitSeconds },
                        set: { model.setHoYoWaitSeconds($0) }
                    )) {
                        Text(tr("10 秒", "10s")).tag(10)
                        Text(tr("15 秒", "15s")).tag(15)
                        Text(tr("20 秒", "20s")).tag(20)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 180)
                    .disabled(model.isHoYoAssistantRunning)

                    Spacer()
                }
            }
            .padding(6)
        }
    }
}
