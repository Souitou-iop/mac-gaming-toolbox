import AppKit
import Foundation
#if SWIFT_PACKAGE
import MacGameToolboxCore
#endif

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    static let shared = StatusBarController()

    private var statusItem: NSStatusItem?
    private weak var model: AppModel?

    private override init() {
        super.init()
    }

    func setup(model: AppModel) {
        self.model = model
        guard statusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "gamecontroller.fill", accessibilityDescription: "Mac Gaming Toolbox")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        item.menu = menu
        self.statusItem = item
    }

    // MARK: - Dynamic Menu Builder

    public func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        guard let model else { return }

        // 1. Window Control
        let isWindowVisible = NSApp.windows.contains { !($0 is NSPanel) && $0.canBecomeMain && $0.isVisible }
        let windowItem = NSMenuItem(
            title: isWindowVisible ? tr("隐藏主窗口", "Hide Main Window", "メインウィンドウを隠す") : tr("显示主窗口", "Show Main Window", "メインウィンドウを表示"),
            action: #selector(toggleMainWindow),
            keyEquivalent: "o"
        )
        windowItem.target = self
        menu.addItem(windowItem)

        menu.addItem(.separator())

        // 2. Section: Resolution Scaling & Frame Generation
        buildScalingSection(menu: menu, model: model)

        menu.addItem(.separator())

        // 3. Section: Metal HUD & Per-App Injection
        buildMetalHUDSection(menu: menu, model: model)

        menu.addItem(.separator())

        // 4. Section: Game Boost & Launch Optimization
        buildGameBoostSection(menu: menu, model: model)

        menu.addItem(.separator())

        // 5. Utility & Quit
        let aboutItem = NSMenuItem(
            title: tr("关于与致谢…", "About & Credits…", "情報と謝辞…"),
            action: #selector(showAboutWindow),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(
            title: tr("退出 Mac 游戏工具箱", "Quit Mac Gaming Toolbox", "Macゲームツールボックスを終了"),
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Section Builders

    private func buildScalingSection(menu: NSMenu, model: AppModel) {
        let header = NSMenuItem(title: tr("⚡ 画质超分与动态补帧", "⚡ Scaling & Frame Gen", "⚡ 超解像と動的補フレーム"), action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        // Toggle Scaling
        let toggleItem = NSMenuItem(
            title: model.isScalingActive ? tr("已开启画质超分与补帧", "Scaling & FG Active", "超解像・補正実行中") : tr("开启画质超分与补帧", "Start Scaling & Frame Gen", "超解像・補フレームを開始"),
            action: #selector(toggleScaling),
            keyEquivalent: "t"
        )
        toggleItem.keyEquivalentModifierMask = [.command, .shift]
        toggleItem.target = self
        toggleItem.state = model.isScalingActive ? .on : .off
        menu.addItem(toggleItem)

        // Target Window Submenu
        let targetMenu = NSMenu(title: tr("目标窗口", "Target Window", "対象ウィンドウ"))
        if model.availableWindows.isEmpty {
            let empty = NSMenuItem(title: tr("(未选择或未检测到窗口)", "(No active windows)", "(ウィンドウ未検出)"), action: nil, keyEquivalent: "")
            empty.isEnabled = false
            targetMenu.addItem(empty)
        } else {
            for win in model.availableWindows {
                let winItem = NSMenuItem(
                    title: "\(win.appName) - \(win.title)",
                    action: #selector(selectTargetWindow(_:)),
                    keyEquivalent: ""
                )
                winItem.target = self
                winItem.representedObject = win.id
                winItem.state = (model.selectedWindowID == win.id) ? .on : .off
                targetMenu.addItem(winItem)
            }
        }
        let refreshItem = NSMenuItem(
            title: tr("🔄 刷新窗口列表…", "🔄 Refresh Windows…", "🔄 ウィンドウ一覧を更新…"),
            action: #selector(refreshWindows),
            keyEquivalent: ""
        )
        refreshItem.target = self
        targetMenu.addItem(.separator())
        targetMenu.addItem(refreshItem)

        let targetSubmenuItem = NSMenuItem(title: tr("目标游戏窗口", "Target Window", "対象ウィンドウ"), action: nil, keyEquivalent: "")
        targetSubmenuItem.submenu = targetMenu
        menu.addItem(targetSubmenuItem)

        // Frame Gen Mode Submenu
        let fgMenu = NSMenu(title: tr("补帧模式", "Frame Gen Mode", "補フレームモード"))
        for mode in FrameGenMode.allCases {
            let modeItem = NSMenuItem(
                title: tr(mode.titleZh, mode.titleEn, mode.titleJa),
                action: #selector(selectFrameGenMode(_:)),
                keyEquivalent: ""
            )
            modeItem.target = self
            modeItem.representedObject = mode
            modeItem.state = (model.configuration.scalingSettings.frameGenMode == mode) ? .on : .off
            fgMenu.addItem(modeItem)
        }
        let fgSubmenuItem = NSMenuItem(title: tr("补帧算法模式", "Frame Gen Mode", "補フレームモード"), action: nil, keyEquivalent: "")
        fgSubmenuItem.submenu = fgMenu
        menu.addItem(fgSubmenuItem)

        // Anti-Aliasing Submenu
        let aaMenu = NSMenu(title: tr("抗锯齿方案", "Anti-Aliasing", "アンチエイリアス"))
        for aa in ScalingAAMode.allCases {
            let aaItem = NSMenuItem(
                title: tr(aa.titleZh, aa.titleEn, aa.titleJa),
                action: #selector(selectAAMode(_:)),
                keyEquivalent: ""
            )
            aaItem.target = self
            aaItem.representedObject = aa
            aaItem.state = (model.configuration.scalingSettings.aaMode == aa) ? .on : .off
            aaMenu.addItem(aaItem)
        }
        let aaSubmenuItem = NSMenuItem(title: tr("抗锯齿方案", "Anti-Aliasing", "アンチエイリアス"), action: nil, keyEquivalent: "")
        aaSubmenuItem.submenu = aaMenu
        menu.addItem(aaSubmenuItem)

        // CAS Sharpening Toggle
        let casItem = NSMenuItem(
            title: tr("CAS 对比度自适应锐化", "CAS Contrast Sharpening", "CAS コントラスト適応鮮鋭化"),
            action: #selector(toggleCAS),
            keyEquivalent: ""
        )
        casItem.target = self
        casItem.state = model.configuration.scalingSettings.casEnabled ? .on : .off
        menu.addItem(casItem)
    }

    private func buildMetalHUDSection(menu: NSMenu, model: AppModel) {
        let header = NSMenuItem(title: tr("📊 Metal HUD 性能监视器", "📊 Metal HUD Performance Monitor", "📊 Metal HUD パフォーマンス"), action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        // Global HUD Switch
        let globalHUDItem = NSMenuItem(
            title: tr("全局启用 Metal HUD", "Enable Metal HUD Globally", "Metal HUD をグローバル有効化"),
            action: #selector(toggleGlobalMetalHUD),
            keyEquivalent: ""
        )
        globalHUDItem.target = self
        globalHUDItem.state = model.metalHUDEnabled ? .on : .off
        menu.addItem(globalHUDItem)

        // HUD Presets Submenu
        let presetMenu = NSMenu(title: tr("HUD 预设方案", "HUD Presets", "HUD プリセット"))
        let currentPreset = model.currentMetalHUDPreset()

        let minimalItem = NSMenuItem(title: tr("精简模式 (FPS/内存/温度)", "Minimal (FPS/Memory/Thermal)", "最小 (FPS/メモリ/温度)"), action: #selector(applyPresetMinimal), keyEquivalent: "")
        minimalItem.target = self
        minimalItem.state = (currentPreset == .minimal) ? .on : .off
        presetMenu.addItem(minimalItem)

        let balancedItem = NSMenuItem(title: tr("均衡模式 (FPS图表/GPU时间)", "Balanced (FPS Graph/GPU Time)", "バランス (FPSグラフ/GPU時間)"), action: #selector(applyPresetBalanced), keyEquivalent: "")
        balancedItem.target = self
        balancedItem.state = (currentPreset == .balanced) ? .on : .off
        presetMenu.addItem(balancedItem)

        let complexItem = NSMenuItem(title: tr("完整分析 (全指标/着色器/IO)", "Complex (All Metrics/Shaders)", "完全分析 (全項目/シェーダー)"), action: #selector(applyPresetComplex), keyEquivalent: "")
        complexItem.target = self
        complexItem.state = (currentPreset == .complex) ? .on : .off
        presetMenu.addItem(complexItem)

        let presetSubmenuItem = NSMenuItem(title: tr("HUD 预设方案", "HUD Presets", "HUD プリセット"), action: nil, keyEquivalent: "")
        presetSubmenuItem.submenu = presetMenu
        menu.addItem(presetSubmenuItem)

        // Per-App HUD Quick Launch Submenu
        let perAppMenu = NSMenu(title: tr("单应用 HUD 注入启动", "Per-App HUD Launcher", "単体アプリ HUD 起動"))
        if model.configuration.recentMetalHUDApps.isEmpty {
            let empty = NSMenuItem(title: tr("(暂无添加的游戏，请在主程序添加)", "(No games in library)", "(登録されたゲームがありません)"), action: nil, keyEquivalent: "")
            empty.isEnabled = false
            perAppMenu.addItem(empty)
        } else {
            for app in model.configuration.recentMetalHUDApps {
                let hasCustomProfile = model.profileForApp(path: app.path) != nil
                let suffix = hasCustomProfile ? tr(" [专属HUD]", " [Custom]", " [個別]") : ""
                let appItem = NSMenuItem(
                    title: "\(app.displayName)\(suffix)",
                    action: #selector(launchSingleHUDApp(_:)),
                    keyEquivalent: ""
                )
                appItem.target = self
                appItem.representedObject = app.path
                appItem.image = NSWorkspace.shared.icon(forFile: app.path)
                appItem.image?.size = NSSize(width: 16, height: 16)
                perAppMenu.addItem(appItem)
            }
        }
        perAppMenu.addItem(.separator())
        let openLauncherItem = NSMenuItem(
            title: tr("🎮 打开游戏选择启动器 (多选批量)…", "🎮 Open Launcher Box (Multi-Launch)…", "🎮 選択起動マネージャーを開く (一括起動)…"),
            action: #selector(openHUDAppLauncherBox),
            keyEquivalent: ""
        )
        openLauncherItem.target = self
        perAppMenu.addItem(openLauncherItem)

        let perAppSubmenuItem = NSMenuItem(title: tr("🚀 单应用 HUD 启动游戏", "🚀 Launch Games with HUD", "🚀 HUD付きでゲーム起動"), action: nil, keyEquivalent: "")
        perAppSubmenuItem.submenu = perAppMenu
        menu.addItem(perAppSubmenuItem)

        // Restart Stale Processes
        let restartProcessesItem = NSMenuItem(
            title: tr("排查并重启冲突进程 (Steam/Wine)…", "Restart Conflicting Processes…", "競合プロセスを再起動…"),
            action: #selector(openProcessManager),
            keyEquivalent: ""
        )
        restartProcessesItem.target = self
        menu.addItem(restartProcessesItem)
    }

    private func buildGameBoostSection(menu: NSMenu, model: AppModel) {
        let header = NSMenuItem(title: tr("🚀 游戏优化与启动", "🚀 Game Boost & Launch", "🚀 ゲーム高速化と起動"), action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        // Gaming Focus Toggle
        let focusItem = NSMenuItem(
            title: tr("游戏专注防休眠 (Caffeinate 保持高刷)", "Gaming Focus (Anti-Sleep)", "ゲーム集中モード (スリープ・降頻防止)"),
            action: #selector(toggleGamingFocus),
            keyEquivalent: ""
        )
        focusItem.target = self
        focusItem.state = model.isGamingFocusActive ? .on : .off
        menu.addItem(focusItem)

        // Priority Boost Action
        let priorityItem = NSMenuItem(
            title: tr("优化 Wine 进程算力优先级 (Renice -20)", "Boost Wine Priority (Renice -20)", "Wine プロセスの優先度最適化 (Renice -20)"),
            action: #selector(boostWinePriority),
            keyEquivalent: ""
        )
        priorityItem.target = self
        menu.addItem(priorityItem)

        // SteamDeck Mode Toggle
        let isSteamDeck = model.configuration.hostnameBackup != nil
        let steamDeckItem = NSMenuItem(
            title: isSteamDeck ? tr("恢复原生 Mac 主机名", "Restore Native Hostname", "Mac標準ホスト名に復元") : tr("切换至 SteamDeck 反作弊伪装", "Enable SteamDeck Spoofing", "SteamDeck 偽装を有効化"),
            action: #selector(toggleSteamDeck),
            keyEquivalent: ""
        )
        steamDeckItem.target = self
        steamDeckItem.state = isSteamDeck ? .on : .off
        menu.addItem(steamDeckItem)

        // HoYoGames Assistant Action
        let hoyoItem = NSMenuItem(
            title: model.isHoYoAssistantRunning ? tr("取消 HoYoGames 启动辅助", "Cancel HoYoGames Assistant", "HoYoGames 起動補助をキャンセル") : tr("HoYoGames 启动辅助 (15s hosts 代理)", "HoYoGames Launch Assistant", "HoYoGames 起動補助 (15秒)"),
            action: #selector(toggleHoYoAssistant),
            keyEquivalent: ""
        )
        hoyoItem.target = self
        hoyoItem.state = model.isHoYoAssistantRunning ? .on : .off
        menu.addItem(hoyoItem)
    }

    // MARK: - Menu Actions

    @objc private func toggleMainWindow() {
        let isWindowVisible = NSApp.windows.contains { !($0 is NSPanel) && $0.canBecomeMain && $0.isVisible }
        if isWindowVisible {
            MenuCommandCoordinator.shared.closeWindow()
        } else {
            MenuCommandCoordinator.shared.reopenMainWindow()
        }
    }

    @objc private func toggleScaling() {
        model?.toggleScaling()
    }

    @objc private func selectTargetWindow(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? CGWindowID else { return }
        model?.selectedWindowID = id
        if model?.isScalingActive == true {
            model?.startScaling()
        }
    }

    @objc private func refreshWindows() {
        model?.refreshAvailableWindows()
    }

    @objc private func selectFrameGenMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? FrameGenMode, var s = model?.configuration.scalingSettings else { return }
        s.frameGenMode = mode
        model?.updateScalingSettings(s)
    }

    @objc private func selectAAMode(_ sender: NSMenuItem) {
        guard let aa = sender.representedObject as? ScalingAAMode, var s = model?.configuration.scalingSettings else { return }
        s.aaMode = aa
        model?.updateScalingSettings(s)
    }

    @objc private func toggleCAS() {
        guard var s = model?.configuration.scalingSettings else { return }
        s.casEnabled.toggle()
        model?.updateScalingSettings(s)
    }

    @objc private func toggleGlobalMetalHUD() {
        let current = model?.metalHUDEnabled ?? false
        model?.setMetalHUD(!current)
    }

    @objc private func applyPresetMinimal() {
        model?.applyMetalHUDPreset(.minimal)
    }

    @objc private func applyPresetBalanced() {
        model?.applyMetalHUDPreset(.balanced)
    }

    @objc private func applyPresetComplex() {
        model?.applyMetalHUDPreset(.complex)
    }

    @objc private func launchSingleHUDApp(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        model?.launchRecordedAppWithMetalHUD(path)
    }

    @objc private func openHUDAppLauncherBox() {
        MenuCommandCoordinator.shared.reopenMainWindow()
        model?.openHUDAppLauncher()
    }

    @objc private func openProcessManager() {
        MenuCommandCoordinator.shared.reopenMainWindow()
        model?.openMetalHUDProcessManager()
    }

    @objc private func toggleGamingFocus() {
        model?.toggleGamingFocus()
    }

    @objc private func boostWinePriority() {
        model?.increaseCrossOverPriority()
    }

    @objc private func toggleSteamDeck() {
        model?.toggleSteamDeck()
    }

    @objc private func toggleHoYoAssistant() {
        if model?.isHoYoAssistantRunning == true {
            model?.cancelHoYoAssistant()
        } else {
            model?.startHoYoAssistant()
        }
    }

    @objc private func showAboutWindow() {
        MenuCommandCoordinator.shared.reopenMainWindow()
    }

    @objc private func quitApp() {
        MenuCommandCoordinator.shared.quitApplication()
    }
}
