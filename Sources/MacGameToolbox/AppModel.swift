import AppKit
import Combine
import Foundation
import SwiftUI
import UniformTypeIdentifiers
#if SWIFT_PACKAGE
import MacGameToolboxCore
#endif

enum MetalHUDPreset {
    case minimal, balanced, complex
}

@MainActor
final class AppModel: ObservableObject {
    @Published var status = TaskStatus()
    @Published var configuration = AppConfiguration()
    @Published var disks: [DiskVolume] = []
    @Published var selectedDiskIDs = Set<String>()
    @Published var diskPaths: [String: String] = [:]
    @Published var metalHUDEnabled = false
    @Published var cacheScan: CacheScan?
    @Published var showingDiskManager = false
    @Published var showingCacheConfirmation = false
    @Published var cacheConfirmationStage = 0
    @Published var showingChangelog = false
    @Published var showingTutorials = false
    @Published var isHoYoAssistantRunning = false
    @Published var showingProcessSelection = false
    @Published var runningProcesses: [SystemProcess] = []
    @Published var selectedProcessIDs = Set<Int32>()

    private let privileged = PrivilegedHelperClient()
    private let configurationStore: ConfigurationStore
    private let diskService: DiskService
    private let gamingService: GamingService
    private let hostnameService: HostnameService
    private let cacheService: CacheService
    private let wallpaperService: WallpaperService
    private let diagnosticsService = DiagnosticsService()
    private var hoyoTask: Task<Void, Never>?
    private var automaticMountTask: Task<Void, Never>?
    private var didLaunch = false

    init() {
        configurationStore = ConfigurationStore()
        diskService = DiskService()
        gamingService = GamingService(privileged: privileged)
        hostnameService = HostnameService(privileged: privileged)
        cacheService = CacheService(privileged: privileged)
        wallpaperService = WallpaperService()
        launch()
    }

    func launch() {
        guard !didLaunch else { return }
        didLaunch = true
        DiagnosticFileLogger.write("App launched, version 3.0.7")
        Task {
            do { configuration = try await configurationStore.load() }
            catch { report(error) }
            metalHUDEnabled = await gamingService.metalHUDEnabled()
            if (try? String(contentsOfFile: "/etc/hosts", encoding: .utf8))?.contains("# BEGIN MAC GAME TOOLBOX HOYO") == true {
                await gamingService.cleanStaleHoYoEntries()
            }
            startAutomaticMountMonitoring()
        }
    }

    func setMetalHUD(_ enabled: Bool) {
        runTask(tr("正在更新 MetalHUD", "Updating MetalHUD")) {
            try await self.gamingService.setMetalHUD(enabled: enabled, options: self.configuration.metalHUDOptions)
            self.metalHUDEnabled = enabled
            return enabled ? tr("MetalHUD 已开启", "MetalHUD enabled") : tr("MetalHUD 已关闭", "MetalHUD disabled")
        }
    }

    func launchAppWithMetalHUD() {
        let panel = NSOpenPanel()
        panel.title = tr("选择要启用 MetalHUD 的 App", "Choose an app for MetalHUD")
        panel.prompt = tr("启用并打开", "Enable and Open")
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.resolvesAliases = true
        guard panel.runModal() == .OK, let applicationURL = panel.url else { return }

        launchRecordedAppWithMetalHUD(applicationURL.path)
    }

    func launchRecordedAppWithMetalHUD(_ path: String) {
        let applicationURL = URL(fileURLWithPath: path)
        runTask(tr("正在使用 MetalHUD 启动 App", "Launching app with MetalHUD")) {
            try await self.gamingService.launchWithMetalHUD(applicationPath: applicationURL.path, options: self.configuration.metalHUDOptions)
            self.rememberMetalHUDApp(applicationURL)
            return tr("已使用 MetalHUD 打开 \(applicationURL.deletingPathExtension().lastPathComponent)", "Opened \(applicationURL.deletingPathExtension().lastPathComponent) with MetalHUD")
        }
    }

    func updateMetalHUDOptions(_ options: MetalHUDOptions) {
        configuration.metalHUDOptions = options
        saveConfiguration()
    }

    func applyMetalHUDPreset(_ preset: MetalHUDPreset) {
        var options = configuration.metalHUDOptions
        switch preset {
        case .minimal:
            // 基础运行信息：设备、渲染层尺寸、内存、FPS、热状态
            options.elements = ["device", "layersize", "memory", "fps", "thermal"]
        case .balanced:
            // 调优常用：在极简基础上加入 FPS 图表、GPU 时间、帧间隔、Rosetta 信息、游戏模式、MetalFX，便于判断卡顿来源
            options.elements = ["device", "layersize", "memory", "fps", "fpsgraph", "gputime", "frameinterval", "rosetta", "thermal", "gamemode", "metalfx"]
        case .complex:
            // 性能诊断：加入呈现延迟、帧间隔直方图、命令缓冲区与编码器、磁盘、着色器、Rosetta 信息、游戏模式、MetalFX，用于定位卡顿/瓶颈
            options.elements = ["device", "layersize", "memory", "fps", "fpsgraph", "gputime", "frameinterval", "frameintervalgraph", "frameintervalhistogram", "presentdelay", "metalcpu", "shaders", "disk", "toplabeledcommandbuffers", "toplabeledencoders", "rosetta", "thermal", "gamemode", "metalfx"]
        }
        updateMetalHUDOptions(options)
    }

    func currentMetalHUDPreset() -> MetalHUDPreset? {
        let elements = Set(configuration.metalHUDOptions.elements)
        if elements == Set(["device", "layersize", "memory", "fps", "thermal"]) { return .minimal }
        if elements == Set(["device", "layersize", "memory", "fps", "fpsgraph", "gputime", "frameinterval", "rosetta", "thermal", "gamemode", "metalfx"]) { return .balanced }
        if elements == Set(["device", "layersize", "memory", "fps", "fpsgraph", "gputime", "frameinterval", "frameintervalgraph", "frameintervalhistogram", "presentdelay", "metalcpu", "shaders", "disk", "toplabeledcommandbuffers", "toplabeledencoders", "rosetta", "thermal", "gamemode", "metalfx"]) { return .complex }
        return nil
    }

    func chooseMetalHUDReportURL() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = tr("选择", "Choose")
        panel.directoryURL = URL(fileURLWithPath: Self.defaultReportURLPath, isDirectory: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        var options = configuration.metalHUDOptions
        options.reportURL = url.path
        updateMetalHUDOptions(options)
    }

    func useDefaultReportURL() {
        let path = Self.defaultReportURLPath
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        var options = configuration.metalHUDOptions
        options.reportURL = path
        updateMetalHUDOptions(options)
    }

    func clearMetalHUDReportURL() {
        var options = configuration.metalHUDOptions
        options.reportURL = nil
        updateMetalHUDOptions(options)
    }

    func resetMetalHUDOptions() {
        configuration.metalHUDOptions = MetalHUDOptions()
        saveConfiguration()
        setTransientStatus(.succeeded, message: tr("已重置 Metal HUD 配置", "Metal HUD settings reset"))
    }

    func exportMetalHUDOptions() {
        let panel = NSSavePanel()
        panel.title = tr("导出 Metal HUD 配置", "Export Metal HUD Configuration")
        panel.prompt = tr("导出", "Export")
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "MetalHUD.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(configuration.metalHUDOptions)
            try data.write(to: url)
            setTransientStatus(.succeeded, message: tr("已导出配置", "Configuration exported"))
        } catch {
            report(error)
        }
    }

    func importMetalHUDOptions() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.json]
        panel.title = tr("导入 Metal HUD 配置", "Import Metal HUD Configuration")
        panel.prompt = tr("导入", "Import")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            let options = try JSONDecoder().decode(MetalHUDOptions.self, from: data)
            updateMetalHUDOptions(options)
            setTransientStatus(.succeeded, message: tr("已导入配置", "Configuration imported"))
        } catch {
            report(error)
        }
    }

    func revealReportURLInFinder() {
        guard let path = configuration.metalHUDOptions.reportURL else { return }
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
    }

    private static var defaultReportURLPath: String {
        let support = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first
            ?? NSTemporaryDirectory()
        return (support as NSString).appendingPathComponent("MacGameToolbox/HUDReports")
    }

    func openConsoleApp() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Console") else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    func exportRecentHUDLogs() {
        let task = Process()
        task.launchPath = "/usr/bin/log"
        task.arguments = ["show", "--predicate", "subsystem == \"com.apple.metal.hud\"", "--last", "10m", "--style", "syslog"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            let output = String(data: data, encoding: .utf8) ?? ""
            let support = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first
                ?? NSTemporaryDirectory()
            let dir = (support as NSString).appendingPathComponent("MacGameToolbox/HUDLogs")
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let fileName = "MetalHUD_\(formatter.string(from: Date())).log"
            let filePath = (dir as NSString).appendingPathComponent(fileName)
            let header = "Metal HUD Logs (last 10 minutes)\nExported: \(Date())\nFilter: subsystem == \"com.apple.metal.hud\"\n=========================================\n\n"
            let content = header + (output.isEmpty ? "(no logs found)" : output)
            try? content.write(toFile: filePath, atomically: true, encoding: .utf8)
            NSWorkspace.shared.open(URL(fileURLWithPath: filePath))
        } catch {
            report(error)
        }
    }

    func removeRecentMetalHUDApp(_ app: RecentMetalHUDApp) {
        configuration.recentMetalHUDApps.removeAll { $0.path == app.path }
        saveConfiguration()
    }

    func increaseCrossOverPriority() {
        runTask(tr("正在检测 CrossOver", "Detecting CrossOver")) {
            let processes = try await self.gamingService.wineProcesses(crossOverOnly: true)
            DiagnosticFileLogger.write("Detected CrossOver process count: \(processes.count)")
            guard !processes.isEmpty else {
                throw ToolboxError.commandFailed(tr("未检测到 CrossOver 或 Wine 进程", "No CrossOver or Wine process found"))
            }
            self.status.phase = .awaitingAuthorization
            try await self.privileged.perform(.renice(processes.map(\.pid)))
            return tr("已提高 \(processes.count) 个进程的优先级", "Updated \(processes.count) processes")
        }
    }

    func loadProcessesForManualSelection() {
        showingProcessSelection = true
        runningProcesses = []
        selectedProcessIDs.removeAll()
        Task {
            do { runningProcesses = try await gamingService.runningProcesses() }
            catch { report(error) }
        }
    }

    func increaseSelectedProcessPriority() {
        let identifiers = Array(selectedProcessIDs)
        guard !identifiers.isEmpty else { return }
        showingProcessSelection = false
        runTask(tr("正在提高所选进程优先级", "Increasing selected process priority")) {
            self.status.phase = .awaitingAuthorization
            try await self.privileged.perform(.renice(identifiers))
            return tr("已提高 \(identifiers.count) 个进程的优先级", "Updated \(identifiers.count) selected process(es)")
        }
    }

    func setHoYoWaitSeconds(_ seconds: Int) {
        guard [10, 15, 20].contains(seconds) else { return }
        configuration.hoYoWaitSeconds = seconds
        saveConfiguration()
    }

    func startHoYoAssistant() {
        guard hoyoTask == nil else { return }
        let waitSeconds = configuration.hoYoWaitSeconds
        isHoYoAssistantRunning = true
        setAnimatedStatus(TaskStatus(phase: .awaitingAuthorization, message: tr("正在启用系统辅助服务", "Enabling system helper"), progress: 0, log: []))
        hoyoTask = Task {
            do {
                try await gamingService.beginHoYoLaunch()
                status.phase = .running
                status.log.append(tr("已写入临时 hosts，等待 \(waitSeconds) 秒", "Temporary hosts applied; waiting \(waitSeconds) seconds"))
                for remaining in stride(from: waitSeconds, through: 1, by: -1) {
                    try Task.checkCancellation()
                    status.message = tr("请启动游戏，剩余 \(remaining) 秒", "Launch the game; \(remaining) seconds remaining")
                    status.progress = Double(waitSeconds - remaining) / Double(waitSeconds)
                    try await Task.sleep(for: .seconds(1))
                }

                try Task.checkCancellation()
                status.message = tr("正在检测 Wine 进程", "Detecting Wine processes")
                status.log.append(tr("等待完成，开始检测 Wine 进程", "Wait complete; detecting Wine processes"))
                let processes = try await gamingService.wineProcesses()
                DiagnosticFileLogger.write("HoYo Wine check after \(waitSeconds) seconds: \(processes.count) process(es)")
                guard !processes.isEmpty else {
                    throw ToolboxError.commandFailed(tr("\(waitSeconds) 秒后未检测到 Wine 进程", "No Wine process detected after \(waitSeconds) seconds"))
                }

                status.phase = .awaitingAuthorization
                try await privileged.perform(.renice(processes.map(\.pid)))
                try await gamingService.finishHoYoLaunch()
                let logs = status.log
                setTransientStatus(.succeeded, message: tr("已优化 \(processes.count) 个进程并恢复 hosts", "Updated \(processes.count) processes and restored hosts"))
                status.log = logs
            } catch is CancellationError {
                try? await gamingService.finishHoYoLaunch()
                setTransientStatus(.cancelled, message: tr("已取消并恢复 hosts", "Cancelled and restored hosts"))
            } catch {
                try? await gamingService.finishHoYoLaunch()
                report(error)
            }
            hoyoTask = nil
            isHoYoAssistantRunning = false
        }
    }

    func cancelHoYoAssistant() { hoyoTask?.cancel() }

    func loadDisks() {
        showingDiskManager = true
        Task {
            do {
                disks = try await diskService.listEligibleVolumes()
                for preset in configuration.diskPresets { if let path = preset.mountPath { diskPaths[preset.diskIdentifier] = path } }
            } catch { report(error) }
        }
    }

    func choosePath(for diskID: String) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = tr("选择", "Choose")
        if panel.runModal() == .OK, let url = panel.url { diskPaths[diskID] = url.path }
    }

    func mountSelectedDisks() {
        let assignments = selectedDiskIDs.compactMap { id -> (String, String)? in
            guard let path = diskPaths[id], !path.isEmpty else { return nil }
            return (id, path)
        }
        guard assignments.count == selectedDiskIDs.count, !assignments.isEmpty else {
            report(ToolboxError.invalidPath(tr("请为每个磁盘选择路径", "Choose a path for every volume")))
            return
        }
        runTask(tr("正在挂载磁盘", "Mounting volumes")) {
            for (_, path) in assignments {
                if !FileManager.default.fileExists(atPath: path) { try await self.privileged.perform(.createDirectory(path)) }
            }
            let results = await self.diskService.mountBatch(assignments)
            let failures = results.compactMap { key, result -> String? in if case .failure = result { return key }; return nil }
            guard failures.isEmpty else { throw ToolboxError.commandFailed(tr("挂载失败并已回滚：\(failures.joined(separator: ", "))", "Mount failed and rolled back: \(failures.joined(separator: ", "))")) }
            self.rememberRestorableMounts(assignments)
            return tr("已成功挂载 \(assignments.count) 个卷", "Mounted \(assignments.count) volume(s)")
        }
    }

    func restoreSelectedDisks() {
        runTask(tr("正在恢复默认挂载", "Restoring default mounts")) {
            for identifier in self.selectedDiskIDs { try await self.diskService.restoreDefaultMount(identifier) }
            let selectedUUIDs = Set(self.disks.filter { self.selectedDiskIDs.contains($0.id) }.compactMap(\.volumeUUID))
            self.configuration.restorableDiskMounts.removeAll {
                self.selectedDiskIDs.contains($0.diskIdentifier) || ($0.volumeUUID.map(selectedUUIDs.contains) ?? false)
            }
            self.saveConfiguration()
            return tr("已恢复系统默认挂载路径", "Default mounts restored")
        }
    }

    func saveDiskPreset(_ identifier: String) {
        configuration.diskPresets.removeAll { $0.diskIdentifier == identifier }
        configuration.diskPresets.insert(DiskPreset(diskIdentifier: identifier, mountPath: diskPaths[identifier]), at: 0)
        configuration.diskPresets = Array(configuration.diskPresets.prefix(ConfigurationStore.maxPresets))
        saveConfiguration()
    }

    func deleteDiskPreset(_ identifier: String) {
        configuration.diskPresets.removeAll { $0.diskIdentifier == identifier }
        saveConfiguration()
    }

    func setAutomaticallyRestoreMountsOnLaunch(_ enabled: Bool) {
        configuration.automaticallyRestoreMountsOnLaunch = enabled
        saveConfiguration()
        startAutomaticMountMonitoring()
    }

    func restorePreviousMounts() {
        setAnimatedStatus(TaskStatus(phase: .running, message: tr("正在恢复上次挂载", "Restoring previous mounts")))
        Task {
            do {
                let availableVolumes = try await diskService.listEligibleVolumes()
                disks = availableVolumes
                enrichRestorableMountUUIDs(from: availableVolumes)
                guard !configuration.restorableDiskMounts.isEmpty else {
                    throw ToolboxError.commandFailed(tr("没有可恢复的挂载记录", "No previous mounts to restore"))
                }
                await restoreMounts(from: availableVolumes, manual: true)
            } catch { report(error) }
        }
    }

    func addDefaultPath() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = tr("添加", "Add")
        guard panel.runModal() == .OK, let path = panel.url?.path else { return }
        configuration.defaultPaths.removeAll { $0 == path }
        configuration.defaultPaths.insert(path, at: 0)
        configuration.defaultPaths = Array(configuration.defaultPaths.prefix(ConfigurationStore.maxDefaultPaths))
        saveConfiguration()
    }

    func deleteDefaultPath(_ path: String) {
        configuration.defaultPaths.removeAll { $0 == path }
        saveConfiguration()
    }

    func importWallpaper() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]
        panel.title = tr("导入壁纸", "Import Wallpaper")
        panel.prompt = tr("导入", "Import")
        guard panel.runModal() == .OK, let source = panel.url else { return }

        do {
            let oldPath = configuration.customWallpaperPath
            let destination = try wallpaperService.importWallpaper(from: source, replacing: oldPath)
            configuration.customWallpaperPath = destination.path
            saveConfiguration()
            DiagnosticFileLogger.write("Custom wallpaper imported: \(destination.path)")
            setTransientStatus(.succeeded, message: tr("已导入自定义背景", "Custom wallpaper imported"))
        } catch {
            report(error)
        }
    }

    func resetWallpaper() {
        let oldPath = configuration.customWallpaperPath
        configuration.customWallpaperPath = nil
        saveConfiguration()
        do {
            let removed = try wallpaperService.removeManagedWallpaper(at: oldPath)
            DiagnosticFileLogger.write("Custom wallpaper cleared; removed file: \(removed)")
        } catch {
            DiagnosticFileLogger.write("Custom wallpaper cleared; failed to remove file: \(error.localizedDescription)")
        }
        setTransientStatus(.succeeded, message: tr("已恢复默认背景", "Default background restored"))
    }

    func prepareCacheScan() {
        setAnimatedStatus(TaskStatus(phase: .running, message: tr("正在扫描缓存", "Scanning caches")))
        Task {
            cacheScan = await cacheService.scan(excludingSensitiveFiles: configuration.excludesSensitiveCacheFiles)
            cacheConfirmationStage = 1
            showingCacheConfirmation = true
            setAnimatedStatus(TaskStatus())
        }
    }

    func confirmCacheCleaning() {
        if cacheConfirmationStage == 1, !configuration.excludesSensitiveCacheFiles {
            cacheConfirmationStage = 2
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.showingCacheConfirmation = true }
            return
        }
        guard let scan = cacheScan else { return }
        runTask(tr("正在清理缓存", "Cleaning caches")) {
            if !scan.systemTargets.isEmpty { self.status.phase = .awaitingAuthorization }
            try await self.cacheService.clear(scan)
            return tr("缓存清理完成", "Cache cleaning completed")
        }
    }

    func setExcludesSensitiveCacheFiles(_ enabled: Bool) {
        configuration.excludesSensitiveCacheFiles = enabled
        saveConfiguration()
    }

    func toggleSteamDeck() {
        runTask(tr("正在读取设备名称", "Reading hostnames")) {
            let current = try await self.hostnameService.current()
            self.status.phase = .awaitingAuthorization
            if current.computerName == "steamdeck" {
                guard let backup = self.configuration.hostnameBackup else { throw ToolboxError.commandFailed(tr("找不到原始设备名称备份", "Hostname backup is missing")) }
                try await self.hostnameService.restore(backup)
                self.configuration.hostnameBackup = nil
                self.saveConfiguration()
                return tr("已恢复原始设备名称", "Original hostnames restored")
            }
            self.configuration.hostnameBackup = current
            self.saveConfiguration()
            try await self.hostnameService.setSteamDeck()
            return tr("已切换至 SteamDeck 模式", "SteamDeck mode enabled")
        }
    }

    func requestDiagnosticsExport() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = tr("Mac游戏工具箱-诊断-\(Self.diagnosticTimestamp()).txt", "MacGameToolbox-Diagnostics-\(Self.diagnosticTimestamp()).txt")
        panel.title = tr("导出诊断日志", "Export Diagnostics")
        panel.prompt = tr("导出", "Export")
        guard panel.runModal() == .OK, let destination = panel.url else { return }
        exportDiagnostics(to: destination)
    }

    func repairCoreFeatures() {
        runTask(tr("正在修复核心功能", "Repairing core features")) {
            self.status.phase = .awaitingAuthorization
            try await Self.runCoreFeatureRepairScript()
            return tr("核心功能已修复", "Core features repaired")
        }
    }

    func exportDiagnostics(to destination: URL) {
        let currentStatus = status
        let currentConfiguration = configuration
        let helperStatus = privileged.diagnosticStatus()
        setAnimatedStatus(TaskStatus(phase: .running, message: tr("正在收集诊断日志", "Collecting diagnostics")))
        DiagnosticFileLogger.write("Diagnostics export started: \(destination.path)")
        do {
            try (tr("诊断日志正在收集，请稍候…", "Diagnostics collection in progress…") + "\n").write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            report(error)
            return
        }
        Task {
            let diagnosticsText = await diagnosticsService.collect(taskStatus: currentStatus, helperStatus: helperStatus, configuration: currentConfiguration)
            do {
                try diagnosticsText.write(to: destination, atomically: true, encoding: .utf8)
                DiagnosticFileLogger.write("Diagnostics exported: \(destination.path)")
                setTransientStatus(.succeeded, message: tr("诊断日志已导出：\(destination.path)", "Diagnostics exported: \(destination.path)"))
                NSWorkspace.shared.activateFileViewerSelecting([destination])
            } catch { report(error) }
        }
    }

    private static func diagnosticTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    private static func runCoreFeatureRepairScript() async throws {
        let shellScript = """
        /bin/launchctl bootout system /Library/LaunchDaemons/com.iven.macgametoolbox.helper.v8.plist 2>/dev/null || true
        /bin/launchctl enable system/com.iven.macgametoolbox.helper.v8
        /bin/launchctl bootstrap system /Library/LaunchDaemons/com.iven.macgametoolbox.helper.v8.plist
        """
        let appleScript = """
        on run argv
            do shell script item 1 of argv with administrator privileges
        end run
        """

        let result: (Int32, String, String) = try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", appleScript, "--", shellScript]
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            try process.run()
            process.waitUntilExit()
            let output = String(decoding: outputPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let error = String(decoding: errorPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (process.terminationStatus, output, error)
        }.value

        guard result.0 == 0 else {
            if result.2.contains("(-128)") { throw ToolboxError.authorizationCancelled }
            let message = result.2.isEmpty ? result.1 : result.2
            throw ToolboxError.commandFailed(message.isEmpty ? tr("核心功能修复失败", "Core feature repair failed") : message)
        }
    }

    private func startAutomaticMountMonitoring() {
        automaticMountTask?.cancel()
        automaticMountTask = nil
        guard configuration.automaticallyRestoreMountsOnLaunch else { return }
        automaticMountTask = Task { [weak self] in
            await self?.monitorDisksAndRestoreMounts()
        }
    }

    private func monitorDisksAndRestoreMounts() async {
        let clock = ContinuousClock()
        let startedAt = clock.now
        var nextLogSecond = 0
        while !Task.isCancelled, configuration.automaticallyRestoreMountsOnLaunch {
            do {
                let availableVolumes = try await diskService.listEligibleVolumes()
                disks = availableVolumes
                enrichRestorableMountUUIDs(from: availableVolumes)
                let elapsedSeconds = Int(startedAt.duration(to: clock.now).components.seconds)
                if elapsedSeconds >= nextLogSecond {
                    let identifiers = availableVolumes.map {
                        "\($0.id)[\($0.volumeUUID ?? "no-uuid")]=\($0.mountPoint ?? "unmounted")"
                    }.joined(separator: ", ")
                    DiagnosticFileLogger.write("Automatic disk scan \(elapsedSeconds)s: \(identifiers.isEmpty ? "no eligible volumes" : identifiers)")
                    nextLogSecond = max(10, ((elapsedSeconds / 10) + 1) * 10)
                }
                if elapsedSeconds >= 10 { await restoreMounts(from: availableVolumes) }
            } catch {
                DiagnosticFileLogger.write("Automatic disk refresh failed: \(error.localizedDescription)")
            }
            do { try await Task.sleep(for: .seconds(1)) }
            catch { return }
        }
    }

    private func restoreMounts(from volumes: [DiskVolume], manual: Bool = false) async {
        let assignments = configuration.restorableDiskMounts.compactMap { preset -> (String, String)? in
            guard let path = preset.mountPath,
                  let volume = DiskService.matchingVolume(for: preset, in: volumes),
                  volume.mountPoint != path,
                  FileManager.default.fileExists(atPath: path) else { return nil }
            return (volume.id, path)
        }
        guard !assignments.isEmpty else {
            if manual {
                report(ToolboxError.commandFailed(tr("没有找到可恢复的磁盘和路径", "No matching volume and path found to restore")))
                return
            }
            if !configuration.restorableDiskMounts.isEmpty {
                DiagnosticFileLogger.write("Automatic mount restore waiting: no matching unmounted target with an existing path")
            }
            return
        }

        setAnimatedStatus(TaskStatus(phase: .running, message: tr("正在自动恢复上次挂载", "Restoring previous mounts")))
        let results = await diskService.mountBatch(assignments)
        let succeeded = assignments.filter {
            guard case .success? = results[$0.0] else { return false }
            return true
        }
        if succeeded.count == assignments.count {
            rememberRestorableMounts(succeeded)
            DiagnosticFileLogger.write("Automatically restored \(succeeded.count) mount(s)")
            setTransientStatus(.succeeded, message: tr("已自动恢复 \(succeeded.count) 个卷的挂载", "Restored \(succeeded.count) previous mount(s)"))
        } else {
            report(ToolboxError.commandFailed(tr("自动恢复上次挂载失败", "Failed to restore previous mounts")))
        }
    }

    private func rememberRestorableMounts(_ assignments: [(String, String)]) {
        let identifiers = Set(assignments.map(\.0))
        let presets = assignments.map { identifier, path in
            let volume = disks.first { $0.id == identifier }
            return DiskPreset(diskIdentifier: identifier, volumeUUID: volume?.volumeUUID, mountPath: path)
        }
        let volumeUUIDs = Set(presets.compactMap(\.volumeUUID))
        configuration.restorableDiskMounts.removeAll {
            identifiers.contains($0.diskIdentifier) || ($0.volumeUUID.map(volumeUUIDs.contains) ?? false)
        }
        configuration.restorableDiskMounts.insert(contentsOf: presets, at: 0)
        saveConfiguration()
    }

    private func enrichRestorableMountUUIDs(from volumes: [DiskVolume]) {
        var changed = false
        for index in configuration.restorableDiskMounts.indices where configuration.restorableDiskMounts[index].volumeUUID == nil {
            let identifier = configuration.restorableDiskMounts[index].diskIdentifier
            guard let volumeUUID = volumes.first(where: { $0.id == identifier })?.volumeUUID else { continue }
            configuration.restorableDiskMounts[index].volumeUUID = volumeUUID
            changed = true
            DiagnosticFileLogger.write("Added volume UUID to automatic restore record: \(identifier) -> \(volumeUUID)")
        }
        if changed { saveConfiguration() }
    }

    private func saveConfiguration() {
        let value = configuration
        Task { try? await configurationStore.save(value) }
    }

    private func rememberMetalHUDApp(_ applicationURL: URL) {
        let normalizedURL = applicationURL.standardizedFileURL
        let displayName = FileManager.default.displayName(atPath: normalizedURL.path)
        let name = (displayName as NSString).deletingPathExtension
        configuration.recentMetalHUDApps.removeAll { $0.path == normalizedURL.path }
        configuration.recentMetalHUDApps.insert(RecentMetalHUDApp(path: normalizedURL.path, displayName: name), at: 0)
        configuration.recentMetalHUDApps = Array(configuration.recentMetalHUDApps.prefix(ConfigurationStore.maxRecentMetalHUDApps))
        saveConfiguration()
    }

    private func setAnimatedStatus(_ newStatus: TaskStatus) {
        withAnimation(.easeInOut(duration: 0.3)) {
            status = newStatus
        }
    }

    private func runTask(_ message: String, operation: @escaping @MainActor () async throws -> String) {
        setAnimatedStatus(TaskStatus(phase: .running, message: message))
        DiagnosticFileLogger.write("Task started: \(message)")
        Task {
            do {
                let result = try await operation()
                DiagnosticFileLogger.write("Task succeeded: \(result)")
                setTransientStatus(.succeeded, message: result)
            } catch is CancellationError {
                setTransientStatus(.cancelled, message: tr("已取消", "Cancelled"))
            } catch { report(error) }
        }
    }

    private func report(_ error: Error) {
        DiagnosticFileLogger.write("Task failed: \(error.localizedDescription)")
        setTransientStatus(error is CancellationError ? .cancelled : .failed, message: error.localizedDescription)
    }

    private var statusClearTask: Task<Void, Never>?

    /// 设置一个终态状态（succeeded/cancelled/failed），并在 5 秒后自动清除为 idle，
    /// 让底部横幅自动消失。若期间发起新任务，旧的清除任务会被取消。
    private func setTransientStatus(_ phase: TaskPhase, message: String, autoClearAfter: TimeInterval = 5) {
        statusClearTask?.cancel()
        setAnimatedStatus(TaskStatus(phase: phase, message: message, progress: phase == .succeeded ? 1 : nil))
        statusClearTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(autoClearAfter))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self else { return }
                self.setAnimatedStatus(TaskStatus())
            }
        }
    }
}
