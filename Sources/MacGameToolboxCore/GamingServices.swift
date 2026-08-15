import Foundation
import AppKit

public enum PrivilegedOperation: Sendable, Equatable {
    case healthCheck
    case addHoYoHosts
    case removeHoYoHosts
    case renice([Int32])
    case clearSystemCaches
    case setHostnames(HostnameBackup)
    case createDirectory(String)
}

public protocol PrivilegedOperating: Sendable {
    func perform(_ operation: PrivilegedOperation) async throws
}

public actor GamingService {
    public static let hoyoDomains = [
        "globaldp-prod-cn01.bhsr.com", "globaldp-prod-os01.starrails.com",
        "dispatchcnglobal.yuanshen.com", "dispatchosglobal.yuanshen.com",
        "globaldp-prod-cn01.juequling.com", "globaldp-prod-cn02.juequling.com",
        "globaldp-prod-os01.zenlesszonezero.com", "globaldp-prod-os02.zenlesszonezero.com"
    ]

    private let runner: any CommandRunning
    private let privileged: any PrivilegedOperating

    public init(runner: any CommandRunning = ProcessCommandRunner(), privileged: any PrivilegedOperating) {
        self.runner = runner
        self.privileged = privileged
    }

    public func metalHUDEnabled() async -> Bool {
        guard let result = try? await runner.run("/bin/launchctl", arguments: ["getenv", "MTL_HUD_ENABLED"]) else { return false }
        return result.outputString == "1"
    }

    public func metalHUDOptions() async -> MetalHUDOptions {
        func getString(_ key: String) async -> String? {
            let value = (try? await runner.run("/bin/launchctl", arguments: ["getenv", key]).outputString)
            return value.flatMap { $0.isEmpty ? nil : $0 }
        }
        func getDouble(_ key: String) async -> Double? {
            guard let s = await getString(key) else { return nil }
            return Double(s)
        }
        func getInt(_ key: String) async -> Int? {
            guard let s = await getString(key) else { return nil }
            return Int(s)
        }
        func getBool(_ key: String) async -> Bool {
            await getString(key) == "1"
        }
        let opacity = await getDouble("MTL_HUD_OPACITY") ?? 1.0
        let scale = await getDouble("MTL_HUD_SCALE") ?? 0.2
        let alignment = await getString("MTL_HUD_ALIGNMENT") ?? "topright"
        let positionX = await getInt("MTL_HUD_POSITION_X")
        let positionY = await getInt("MTL_HUD_POSITION_Y")
        let elementsRaw = await getString("MTL_HUD_ELEMENTS")
        let elements: [String] = elementsRaw?
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []
        let logEnabled = await getBool("MTL_HUD_LOG_ENABLED")
        let shaderLogEnabled = await getBool("MTL_HUD_LOG_SHADER_ENABLED")
        let encoderTimingEnabled = await getBool("MTL_HUD_ENCODER_TIMING_ENABLED")
        let encoderGpuTimelineFrameCount = await getInt("MTL_HUD_ENCODER_GPU_TIMELINE_FRAME_COUNT")
        let encoderGpuTimelineSwapDelta = await getInt("MTL_HUD_ENCODER_GPU_TIMELINE_SWAP_DELTA")
        let showZeroMetrics = await getBool("MTL_HUD_SHOW_ZERO_METRICS")
        let showMetricsRange = await getBool("MTL_HUD_SHOW_METRICS_RANGE")
        let metricTimeout = await getInt("MTL_HUD_METRIC_TIMEOUT")
        let insightsEnabled = await getBool("MTL_HUD_INSIGHTS_ENABLED")
        let insightTimeout = await getInt("MTL_HUD_INSIGHT_TIMEOUT")
        let insightReportInterval = await getInt("MTL_HUD_INSIGHT_REPORT_INTERVAL")
        let rusageUpdateInterval = await getInt("MTL_HUD_RUSAGE_UPDATE_INTERVAL")
        let reportURL = await getString("MTL_HUD_REPORT_URL")
        let disableMenuBar = await getBool("MTL_HUD_DISABLE_MENU_BAR")
        let configFilePath = await getString("MTL_HUD_CONFIG_FILE")
        return MetalHUDOptions(
            opacity: opacity,
            scale: scale,
            alignment: alignment,
            positionX: positionX,
            positionY: positionY,
            elements: elements,
            logEnabled: logEnabled,
            shaderLogEnabled: shaderLogEnabled,
            encoderTimingEnabled: encoderTimingEnabled,
            encoderGpuTimelineFrameCount: encoderGpuTimelineFrameCount,
            encoderGpuTimelineSwapDelta: encoderGpuTimelineSwapDelta,
            showZeroMetrics: showZeroMetrics,
            showMetricsRange: showMetricsRange,
            metricTimeout: metricTimeout,
            insightsEnabled: insightsEnabled,
            insightTimeout: insightTimeout,
            insightReportInterval: insightReportInterval,
            rusageUpdateInterval: rusageUpdateInterval,
            reportURL: reportURL,
            disableMenuBar: disableMenuBar,
            configFilePath: configFilePath
        )
    }

    public func setMetalHUD(enabled: Bool, options: MetalHUDOptions = MetalHUDOptions()) async throws {
        if enabled {
            _ = try await runner.run("/bin/launchctl", arguments: ["setenv", "MTL_HUD_ENABLED", "1"])
            _ = try? await runner.run("/usr/bin/defaults", arguments: ["write", "-g", "MetalForceHudEnabled", "-bool", "YES"])
            let envArgs = Self.metalHUDEnvArgs(for: options)
            let setKeys = Set(envArgs.compactMap { arg -> String? in
                guard let equals = arg.firstIndex(of: "=") else { return nil }
                return String(arg[..<equals])
            })
            for key in Self.allMetalHUDEnvKeys where key != "MTL_HUD_ENABLED" && !setKeys.contains(key) {
                _ = try? await runner.run("/bin/launchctl", arguments: ["unsetenv", key])
            }
            for arg in envArgs {
                guard let equals = arg.firstIndex(of: "=") else { continue }
                let key = String(arg[..<equals])
                let value = String(arg[arg.index(after: equals)...])
                _ = try await runner.run("/bin/launchctl", arguments: ["setenv", key, value])
            }
        } else {
            _ = try? await runner.run("/usr/bin/defaults", arguments: ["delete", "-g", "MetalForceHudEnabled"])
            for key in Self.allMetalHUDEnvKeys {
                _ = try? await runner.run("/bin/launchctl", arguments: ["unsetenv", key])
            }
        }
    }

    public func launchWithMetalHUD(applicationPath: String, options: MetalHUDOptions = MetalHUDOptions()) async throws {
        let applicationURL = URL(fileURLWithPath: applicationPath).standardizedFileURL
        guard applicationURL.pathExtension.lowercased() == "app",
              FileManager.default.fileExists(atPath: applicationURL.path) else {
            throw ToolboxError.invalidPath(applicationPath)
        }
        // 使用 `open --env` 将环境变量注入到目标进程；`/usr/bin/env VAR=val open -a` 方式
        // 不会传递变量给 launchd 重新派生的 app 进程，导致 HUD 无法生效。
        var arguments = ["-a", applicationURL.path]
        for arg in Self.metalHUDEnvArgs(for: options, includeEnabled: true) {
            arguments.append(contentsOf: ["--env", arg])
        }
        _ = try await runner.run("/usr/bin/open", arguments: arguments)
    }

    private static let allMetalHUDEnvKeys: [String] = [
        "MTL_HUD_ENABLED",
        "MTL_HUD_OPACITY",
        "MTL_HUD_SCALE",
        "MTL_HUD_ALIGNMENT",
        "MTL_HUD_POSITION_X",
        "MTL_HUD_POSITION_Y",
        "MTL_HUD_ELEMENTS",
        "MTL_HUD_LOG_ENABLED",
        "MTL_HUD_LOG_SHADER_ENABLED",
        "MTL_HUD_ENCODER_TIMING_ENABLED",
        "MTL_HUD_ENCODER_GPU_TIMELINE_FRAME_COUNT",
        "MTL_HUD_ENCODER_GPU_TIMELINE_SWAP_DELTA",
        "MTL_HUD_SHOW_ZERO_METRICS",
        "MTL_HUD_SHOW_METRICS_RANGE",
        "MTL_HUD_METRIC_TIMEOUT",
        "MTL_HUD_INSIGHTS_ENABLED",
        "MTL_HUD_INSIGHT_TIMEOUT",
        "MTL_HUD_INSIGHT_REPORT_INTERVAL",
        "MTL_HUD_RUSAGE_UPDATE_INTERVAL",
        "MTL_HUD_REPORT_URL",
        "MTL_HUD_DISABLE_MENU_BAR",
        "MTL_HUD_CONFIG_FILE"
    ]

    private static func metalHUDEnvArgs(for options: MetalHUDOptions, includeEnabled: Bool = false) -> [String] {
        var args: [String] = []
        if includeEnabled {
            args.append("MTL_HUD_ENABLED=1")
        }
        if options.opacity != 1.0 {
            args.append("MTL_HUD_OPACITY=\(String(format: "%g", options.opacity))")
        }
        if options.scale != 0.2 {
            args.append("MTL_HUD_SCALE=\(String(format: "%g", options.scale))")
        }
        if options.alignment != "topright" {
            args.append("MTL_HUD_ALIGNMENT=\(options.alignment)")
        }
        if let v = options.positionX {
            args.append("MTL_HUD_POSITION_X=\(v)")
        }
        if let v = options.positionY {
            args.append("MTL_HUD_POSITION_Y=\(v)")
        }
        if !options.elements.isEmpty {
            args.append("MTL_HUD_ELEMENTS=\(options.elements.joined(separator: ","))")
        }
        if options.logEnabled {
            args.append("MTL_HUD_LOG_ENABLED=1")
        }
        if options.shaderLogEnabled {
            args.append("MTL_HUD_LOG_SHADER_ENABLED=1")
        }
        if options.encoderTimingEnabled {
            args.append("MTL_HUD_ENCODER_TIMING_ENABLED=1")
        }
        if let v = options.encoderGpuTimelineFrameCount {
            args.append("MTL_HUD_ENCODER_GPU_TIMELINE_FRAME_COUNT=\(v)")
        }
        if let v = options.encoderGpuTimelineSwapDelta {
            args.append("MTL_HUD_ENCODER_GPU_TIMELINE_SWAP_DELTA=\(v)")
        }
        if options.showZeroMetrics {
            args.append("MTL_HUD_SHOW_ZERO_METRICS=1")
        }
        if options.showMetricsRange {
            args.append("MTL_HUD_SHOW_METRICS_RANGE=1")
        }
        if let v = options.metricTimeout {
            args.append("MTL_HUD_METRIC_TIMEOUT=\(v)")
        }
        if options.insightsEnabled {
            args.append("MTL_HUD_INSIGHTS_ENABLED=1")
        }
        if let v = options.insightTimeout {
            args.append("MTL_HUD_INSIGHT_TIMEOUT=\(v)")
        }
        if let v = options.insightReportInterval {
            args.append("MTL_HUD_INSIGHT_REPORT_INTERVAL=\(v)")
        }
        if let v = options.rusageUpdateInterval {
            args.append("MTL_HUD_RUSAGE_UPDATE_INTERVAL=\(v)")
        }
        if let s = options.reportURL, !s.isEmpty {
            args.append("MTL_HUD_REPORT_URL=\(s)")
        }
        if options.disableMenuBar {
            args.append("MTL_HUD_DISABLE_MENU_BAR=1")
        }
        if let s = options.configFilePath, !s.isEmpty {
            args.append("MTL_HUD_CONFIG_FILE=\(s)")
        }
        return args
    }

    public func detectMetalHUDInterferingProcesses(recentAppPaths: [String] = []) async throws -> [MetalHUDProcess] {
        let result = try await runner.run("/bin/ps", arguments: ["-axo", "pid=,ppid=,command="])
        let processes = Self.parseProcessTable(result.outputString)
        return Self.identifyInterferingProcesses(processes, recentAppPaths: recentAppPaths)
    }

    public func terminateProcesses(pids: [Int32], force: Bool = false) async -> (succeeded: [Int32], failed: [Int32]) {
        var succeeded: [Int32] = []
        var failed: [Int32] = []
        for pid in pids {
            let ok = await terminateProcess(pid: pid, force: force)
            if ok {
                succeeded.append(pid)
            } else {
                failed.append(pid)
            }
        }
        return (succeeded, failed)
    }

    public func terminateProcess(pid: Int32, force: Bool = false) async -> Bool {
        guard pid > 1 else { return false }
        if let app = NSRunningApplication(processIdentifier: pid) {
            if force {
                _ = app.forceTerminate()
            } else {
                _ = app.terminate()
            }
        }
        let sigArg = force ? "-9" : "-15"
        let res = try? await runner.run("/bin/kill", arguments: [sigArg, String(pid)])
        return res?.exitCode == 0 || NSRunningApplication(processIdentifier: pid) == nil
    }

    public func wineProcesses(crossOverOnly: Bool = false) async throws -> [(pid: Int32, command: String)] {
        let result = try await runner.run("/bin/ps", arguments: ["-axo", "pid=,ppid=,command="])
        return Self.matchingProcesses(Self.parseProcessTable(result.outputString), crossOverOnly: crossOverOnly)
            .map { ($0.pid, $0.command) }
    }

    public func runningProcesses() async throws -> [SystemProcess] {
        let result = try await runner.run("/bin/ps", arguments: ["-axo", "pid=,ppid=,command="])
        return Self.parseProcessTable(result.outputString)
            .filter { $0.pid > 1 && !$0.command.lowercased().contains("macgametoolbox") }
            .sorted { $0.command.localizedStandardCompare($1.command) == .orderedAscending }
    }

    public func increasePriority(crossOverOnly: Bool = true) async throws -> Int {
        let processes = try await wineProcesses(crossOverOnly: crossOverOnly)
        guard !processes.isEmpty else { throw ToolboxError.commandFailed(coreText("未检测到 Wine 进程", "No Wine process found")) }
        try await privileged.perform(.renice(processes.map(\.pid)))
        return processes.count
    }

    public func beginHoYoLaunch() async throws {
        try await privileged.perform(.addHoYoHosts)
    }

    public func finishHoYoLaunch() async throws {
        try await privileged.perform(.removeHoYoHosts)
    }

    public func cleanStaleHoYoEntries() async {
        try? await privileged.perform(.removeHoYoHosts)
    }

    public static func parseProcessTable(_ text: String) -> [SystemProcess] {
        text.split(separator: "\n").compactMap { line in
            let fields = line.split(maxSplits: 2, whereSeparator: { $0 == " " || $0 == "\t" })
            guard fields.count == 3, let pid = Int32(fields[0]), let parentPID = Int32(fields[1]) else { return nil }
            return SystemProcess(pid: pid, parentPID: parentPID, command: String(fields[2]))
        }
    }

    public static func matchingProcesses(_ processes: [SystemProcess], crossOverOnly: Bool) -> [SystemProcess] {
        let roots = Set(processes.filter {
            let value = $0.command.lowercased()
            return value.contains("crossover.app/contents/macos/crossover") || value.hasSuffix("/crossover")
        }.map(\.pid))
        var descendants = roots
        var addedDescendant = true
        while addedDescendant {
            addedDescendant = false
            for process in processes where descendants.contains(process.parentPID) && !descendants.contains(process.pid) {
                descendants.insert(process.pid)
                addedDescendant = true
            }
        }
        return processes.filter { process in
            let value = process.command.lowercased()
            guard !value.contains("macgametoolbox") else { return false }
            let isWine = value.contains("wine") || value.contains("wineserver") || value.contains("winedevice")
            if !crossOverOnly { return isWine }
            // Wine services commonly detach from CrossOver and are re-parented to
            // launchd. If the CrossOver root has exited, retain Wine detection.
            return roots.isEmpty ? isWine : descendants.contains(process.pid) || (value.contains("crossover") && isWine)
        }
    }

    public static func identifyInterferingProcesses(
        _ processes: [SystemProcess],
        recentAppPaths: [String] = []
    ) -> [MetalHUDProcess] {
        let recentNormalized = Set(recentAppPaths.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })

        let ignoredSubstrings = [
            "macgametoolbox",
            "/system/library/",
            "/usr/libexec/",
            "/usr/sbin/",
            "/usr/bin/",
            "windowserver",
            "dock.app",
            "finder.app",
            "systemsettings.app",
            "safari.app",
            "google chrome.app",
            "xcode.app",
            "terminal.app",
            "iterm.app",
            "visual studio code.app",
            "trae.app",
            "cursor.app",
            "antigravity"
        ]

        var results: [MetalHUDProcess] = []

        for p in processes {
            guard p.pid > 1 else { continue }
            let cmdLower = p.command.lowercased()

            if cmdLower.contains("macgametoolbox") { continue }
            if ignoredSubstrings.contains(where: { cmdLower.contains($0) }) {
                let isWine = cmdLower.contains("wineserver") || cmdLower.contains("wine64") || cmdLower.contains("winedevice")
                let isKnownLauncher = cmdLower.contains("steam") || cmdLower.contains("crossover") || cmdLower.contains("whisky")
                if !isWine && !isKnownLauncher {
                    continue
                }
            }

            if let wine = matchWineRuntime(p) {
                results.append(wine)
                continue
            }

            if let launcher = matchLauncher(p) {
                results.append(launcher)
                continue
            }

            if let game = matchGameOrApp(p, recentPaths: recentNormalized) {
                results.append(game)
                continue
            }
        }

        return results.sorted {
            if $0.category != $1.category {
                return $0.category.rawValue < $1.category.rawValue
            }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    public static func extractAppBundlePath(from command: String) -> String? {
        let pattern = #"(/(?:Applications|Users|Volumes)/[^\s"]+?\.app)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: command, options: [], range: NSRange(location: 0, length: command.utf16.count)),
              let range = Range(match.range(at: 1), in: command) else {
            return nil
        }
        return String(command[range])
    }

    private static func matchLauncher(_ p: SystemProcess) -> MetalHUDProcess? {
        let cmd = p.command
        let cmdLower = cmd.lowercased()

        struct LauncherPattern {
            let matches: (String) -> Bool
            let name: String
            let fallbackBundle: String?
        }

        let patterns: [LauncherPattern] = [
            LauncherPattern(matches: { $0.contains("steam.app") || $0.contains("steam_osx") || $0.hasSuffix("/steam") }, name: "Steam", fallbackBundle: "/Applications/Steam.app"),
            LauncherPattern(matches: { $0.contains("crossover.app") || $0.contains("/crossover") || $0.contains("cxoffice") }, name: "CrossOver", fallbackBundle: "/Applications/CrossOver.app"),
            LauncherPattern(matches: { $0.contains("whisky.app") || $0.contains("/whisky") }, name: "Whisky", fallbackBundle: "/Applications/Whisky.app"),
            LauncherPattern(matches: { $0.contains("heroic.app") || $0.contains("/heroic") }, name: "Heroic Games Launcher", fallbackBundle: "/Applications/Heroic.app"),
            LauncherPattern(matches: { $0.contains("battle.net.app") || $0.contains("battle.net") || $0.contains("agent.app") }, name: "Battle.net", fallbackBundle: "/Applications/Battle.net.app"),
            LauncherPattern(matches: { $0.contains("epic games launcher.app") || $0.contains("epicgameslauncher") }, name: "Epic Games Launcher", fallbackBundle: "/Applications/Epic Games Launcher.app"),
            LauncherPattern(matches: { $0.contains("gog galaxy.app") || $0.contains("galaxyclient") }, name: "GOG Galaxy", fallbackBundle: "/Applications/GOG Galaxy.app"),
            LauncherPattern(matches: { $0.contains("porting kit.app") || $0.contains("portingkit") }, name: "Porting Kit", fallbackBundle: "/Applications/Porting Kit.app"),
            LauncherPattern(matches: { $0.contains("origin.app") || $0.contains("eadesktop") }, name: "EA / Origin", fallbackBundle: "/Applications/Origin.app"),
            LauncherPattern(matches: { $0.contains("playcover.app") }, name: "PlayCover", fallbackBundle: "/Applications/PlayCover.app"),
            LauncherPattern(matches: { $0.contains("ryujinx.app") || $0.contains("/ryujinx") }, name: "Ryujinx", fallbackBundle: "/Applications/Ryujinx.app"),
            LauncherPattern(matches: { $0.contains("rpcs3.app") || $0.contains("/rpcs3") }, name: "RPCS3", fallbackBundle: "/Applications/RPCS3.app"),
            LauncherPattern(matches: { $0.contains("dolphin.app") || $0.contains("/dolphin") }, name: "Dolphin", fallbackBundle: "/Applications/Dolphin.app"),
            LauncherPattern(matches: { $0.contains("pcsx2.app") || $0.contains("/pcsx2") }, name: "PCSX2", fallbackBundle: "/Applications/PCSX2.app")
        ]

        for pat in patterns {
            if pat.matches(cmdLower) {
                let bundle = extractAppBundlePath(from: cmd) ?? pat.fallbackBundle
                return MetalHUDProcess(
                    pid: p.pid,
                    parentPID: p.parentPID,
                    name: pat.name,
                    command: p.command,
                    category: .launcher,
                    appBundlePath: bundle,
                    reasonZh: "启动器常驻后台会导致从其启动的游戏子进程继承旧的环境变量，建议重启启动器。",
                    reasonEn: "Launcher running in background causes child game processes to inherit stale environment variables."
                )
            }
        }
        return nil
    }

    private static func matchWineRuntime(_ p: SystemProcess) -> MetalHUDProcess? {
        let cmd = p.command
        let cmdLower = cmd.lowercased()

        let wineKeywords = [
            "wineserver", "wine64-preloader", "wine-preloader", "wine64",
            "winedevice.exe", "winedevice", "explorer.exe", "services.exe",
            "plugplay.exe", "conhost.exe"
        ]

        for kw in wineKeywords {
            if cmdLower.contains(kw) {
                let fileName = cmd.split(separator: "/").last.map(String.init) ?? kw
                let bundle = extractAppBundlePath(from: cmd)
                return MetalHUDProcess(
                    pid: p.pid,
                    parentPID: p.parentPID,
                    name: fileName.isEmpty ? kw : fileName,
                    command: p.command,
                    category: .wineRuntime,
                    appBundlePath: bundle,
                    reasonZh: "Wine 容器与后台服务持有旧的环境状态，关闭后重启游戏可使新配置生效。",
                    reasonEn: "Wine runtime services hold previous environment states. Closing them resets the bottle environment."
                )
            }
        }
        return nil
    }

    private static func matchGameOrApp(_ p: SystemProcess, recentPaths: Set<String>) -> MetalHUDProcess? {
        let cmd = p.command
        let cmdLower = cmd.lowercased()

        // 1. Matches user-recorded recent MetalHUD apps
        for path in recentPaths {
            if !path.isEmpty && cmdLower.contains(path) {
                let displayName = FileManager.default.displayName(atPath: path)
                let name = (displayName as NSString).deletingPathExtension
                return MetalHUDProcess(
                    pid: p.pid,
                    parentPID: p.parentPID,
                    name: name.isEmpty ? "Game (\(p.pid))" : name,
                    command: p.command,
                    category: .gameOrApp,
                    appBundlePath: path,
                    reasonZh: "游戏在启动时已锁定 Metal 渲染配置，关闭后重新启动即可应用最新的 HUD 样式。",
                    reasonEn: "The game locked its Metal rendering configuration on launch. Restart it to apply the new HUD style."
                )
            }
        }

        // 2. Matches steamapps/common or drive_c games or cxbottle
        if cmdLower.contains("steamapps/common") || cmdLower.contains("drive_c") || cmdLower.contains("cxbottle") {
            let bundle = extractAppBundlePath(from: cmd)
            let rawName = bundle.flatMap { ($0 as NSString).lastPathComponent } ?? cmd.split(separator: "/").last.map(String.init) ?? "Game"
            let name = (rawName as NSString).deletingPathExtension
            return MetalHUDProcess(
                pid: p.pid,
                parentPID: p.parentPID,
                name: name.isEmpty ? "Game (\(p.pid))" : name,
                command: p.command,
                category: .gameOrApp,
                appBundlePath: bundle,
                reasonZh: "游戏在启动时已锁定 Metal 渲染配置，关闭后重新启动即可应用最新的 HUD 样式。",
                reasonEn: "The game locked its Metal rendering configuration on launch. Restart it to apply the new HUD style."
            )
        }

        // 3. Check if running inside an .app under /Applications or ~/Applications
        if let bundle = extractAppBundlePath(from: cmd) {
            let bundleLower = bundle.lowercased()
            if bundleLower.contains("/applications/") {
                let rawName = (bundle as NSString).lastPathComponent
                let name = (rawName as NSString).deletingPathExtension
                return MetalHUDProcess(
                    pid: p.pid,
                    parentPID: p.parentPID,
                    name: name.isEmpty ? "App (\(p.pid))" : name,
                    command: p.command,
                    category: .gameOrApp,
                    appBundlePath: bundle,
                    reasonZh: "应用在启动时已锁定 Metal 渲染配置，关闭后重新启动即可应用最新的 HUD 样式。",
                    reasonEn: "The app locked its Metal rendering configuration on launch. Restart it to apply the new HUD style."
                )
            }
        }

        return nil
    }
}

public actor HostnameService {
    private let runner: any CommandRunning
    private let privileged: any PrivilegedOperating

    public init(runner: any CommandRunning = ProcessCommandRunner(), privileged: any PrivilegedOperating) {
        self.runner = runner
        self.privileged = privileged
    }

    public func current() async throws -> HostnameBackup {
        let computer = try await read("ComputerName")
        let local = (try? await read("LocalHostName")) ?? Self.slug(computer)
        let host = (try? await read("HostName")) ?? local
        return HostnameBackup(computerName: computer, hostName: host, localHostName: local)
    }

    public func setSteamDeck() async throws {
        try await privileged.perform(.setHostnames(HostnameBackup(computerName: "steamdeck", hostName: "steamdeck", localHostName: "steamdeck")))
    }

    public func restore(_ backup: HostnameBackup) async throws {
        try await privileged.perform(.setHostnames(backup))
    }

    private func read(_ key: String) async throws -> String {
        try await runner.run("/usr/sbin/scutil", arguments: ["--get", key]).outputString
    }

    private static func slug(_ value: String) -> String {
        let mapped = value.map { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "." ? $0 : "-" }
        return String(mapped).trimmingCharacters(in: CharacterSet(charactersIn: "-."))
    }
}

// MARK: - Game Save Finder & Bottle Backup Service

public actor GameSaveFinderService {
    private let fileManager: FileManager
    private let runner: any CommandRunning

    public init(fileManager: FileManager = .default, runner: any CommandRunning = ProcessCommandRunner()) {
        self.fileManager = fileManager
        self.runner = runner
    }

    public func discoverBottles() async -> [WineBottle] {
        var bottles: [WineBottle] = []
        let home = fileManager.homeDirectoryForCurrentUser.path

        // 1. CrossOver Bottles
        let crossOverPath = (home as NSString).appendingPathComponent("Library/Application Support/CrossOver/Bottles")
        bottles.append(contentsOf: scanBottleDirectory(at: crossOverPath, type: .crossover))

        // 2. Whisky Bottles
        let whiskyPath = (home as NSString).appendingPathComponent("Library/Application Support/com.isaacmarovitz.Whisky/Bottles")
        bottles.append(contentsOf: scanBottleDirectory(at: whiskyPath, type: .whisky))

        // 3. Heroic Bottles
        let heroicPaths = [
            (home as NSString).appendingPathComponent("Library/Application Support/heroic/prefixes"),
            (home as NSString).appendingPathComponent("Games/Heroic/Prefixes")
        ]
        for hp in heroicPaths {
            bottles.append(contentsOf: scanBottleDirectory(at: hp, type: .heroic))
        }

        // 4. Default Wine Prefix (~/.wine)
        let defaultWinePath = (home as NSString).appendingPathComponent(".wine")
        if fileManager.fileExists(atPath: (defaultWinePath as NSString).appendingPathComponent("drive_c")) {
            bottles.append(WineBottle(name: "Default Wine (~/.wine)", type: .customWine, path: defaultWinePath))
        }

        return bottles
    }

    private func scanBottleDirectory(at basePath: String, type: WineBottleType) -> [WineBottle] {
        guard let items = try? fileManager.contentsOfDirectory(atPath: basePath) else { return [] }
        var result: [WineBottle] = []
        for item in items {
            let fullPath = (basePath as NSString).appendingPathComponent(item)
            let driveC = (fullPath as NSString).appendingPathComponent("drive_c")
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: driveC, isDirectory: &isDir), isDir.boolValue {
                result.append(WineBottle(name: item, type: type, path: fullPath))
            }
        }
        return result
    }

    public func scanSaveDirectories(in bottle: WineBottle) async -> [GameSaveLocation] {
        var saves: [GameSaveLocation] = []
        let driveC = (bottle.path as NSString).appendingPathComponent("drive_c")
        let usersPath = (driveC as NSString).appendingPathComponent("users")
        guard let userDirs = try? fileManager.contentsOfDirectory(atPath: usersPath) else { return [] }

        // Directories to ignore (system/empty standard dirs)
        let ignoredDirs: Set<String> = [
            "microsoft", "temp", "crossover", "public", "all users", "default", "default user",
            "crashdumps", "package cache", "d3dmetal", "dxvk", "nvidia", "amd", "intel",
            "cefdialog", "iconcache.db", "thumbs.db", "desktop.ini", "logs", "cache"
        ]

        for userDir in userDirs {
            let userRoot = (usersPath as NSString).appendingPathComponent(userDir)

            // 1. AppData/Local & AppData/Roaming & AppData/LocalLow
            let appDataCandidates = [
                ("AppData/Local", (userRoot as NSString).appendingPathComponent("AppData/Local")),
                ("AppData/LocalLow", (userRoot as NSString).appendingPathComponent("AppData/LocalLow")),
                ("AppData/Roaming", (userRoot as NSString).appendingPathComponent("AppData/Roaming")),
                ("Local Settings/Application Data", (userRoot as NSString).appendingPathComponent("Local Settings/Application Data"))
            ]
            for (cat, catPath) in appDataCandidates {
                if let gameDirs = try? fileManager.contentsOfDirectory(atPath: catPath) {
                    for gd in gameDirs {
                        if ignoredDirs.contains(gd.lowercased()) || gd.hasPrefix(".") { continue }
                        let full = (catPath as NSString).appendingPathComponent(gd)
                        if let loc = buildSaveLocation(bottleName: bottle.name, gameName: gd, category: cat, path: full) {
                            saves.append(loc)
                        }
                    }
                }
            }

            // 2. Saved Games
            let savedGamesPath = (userRoot as NSString).appendingPathComponent("Saved Games")
            if let gameDirs = try? fileManager.contentsOfDirectory(atPath: savedGamesPath) {
                for gd in gameDirs {
                    if ignoredDirs.contains(gd.lowercased()) || gd.hasPrefix(".") { continue }
                    let full = (savedGamesPath as NSString).appendingPathComponent(gd)
                    if let loc = buildSaveLocation(bottleName: bottle.name, gameName: gd, category: "Saved Games", path: full) {
                        saves.append(loc)
                    }
                }
            }

            // 3. Documents & Documents/My Games
            let myGamesPath = (userRoot as NSString).appendingPathComponent("Documents/My Games")
            if let gameDirs = try? fileManager.contentsOfDirectory(atPath: myGamesPath) {
                for gd in gameDirs {
                    if ignoredDirs.contains(gd.lowercased()) || gd.hasPrefix(".") { continue }
                    let full = (myGamesPath as NSString).appendingPathComponent(gd)
                    if let loc = buildSaveLocation(bottleName: bottle.name, gameName: gd, category: "Documents/My Games", path: full) {
                        saves.append(loc)
                    }
                }
            }
        }

        // Sort by last modified date (newest first)
        return saves.sorted { $0.lastModified > $1.lastModified }
    }

    private func buildSaveLocation(bottleName: String, gameName: String, category: String, path: String) -> GameSaveLocation? {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else { return nil }
        guard let attrs = try? fileManager.attributesOfItem(atPath: path) else { return nil }
        let modDate = attrs[.modificationDate] as? Date ?? Date()
        let sizeFormatted = formatDirectorySize(at: path)
        return GameSaveLocation(
            bottleName: bottleName,
            gameName: gameName,
            category: category,
            path: path,
            sizeFormatted: sizeFormatted,
            lastModified: modDate
        )
    }

    private func formatDirectorySize(at path: String) -> String {
        guard let enumerator = fileManager.enumerator(at: URL(fileURLWithPath: path), includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
            return "0 KB"
        }
        var totalBytes: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]), let size = resourceValues.fileSize {
                totalBytes += Int64(size)
            }
        }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }

    public func createBackupArchive(sourceDirectoryPath: String, destinationZipPath: String) async throws {
        // Use ditto -c -k to create clean macOS-compatible zip archives
        let result = try await runner.run("/usr/bin/ditto", arguments: ["-c", "-k", "--sequesterRsrc", sourceDirectoryPath, destinationZipPath])
        if result.exitCode != 0 {
            throw ToolboxError.commandFailed(result.errorString.isEmpty ? "Zip backup failed" : result.errorString)
        }
    }
}

// MARK: - Gaming Focus Booster (Caffeinate Manager)

public actor GamingFocusBooster {
    private var caffeinateProcess: Process?

    public init() {}

    public var isActive: Bool {
        caffeinateProcess?.isRunning ?? false
    }

    public func start() -> Bool {
        if isActive { return true }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        // -d: prevent display from sleeping
        // -i: prevent system from idle sleeping
        // -m: prevent disk from idle sleeping
        p.arguments = ["-d", "-i", "-m"]
        do {
            try p.run()
            caffeinateProcess = p
            return true
        } catch {
            return false
        }
    }

    public func stop() {
        if let p = caffeinateProcess, p.isRunning {
            p.terminate()
        }
        caffeinateProcess = nil
    }

    deinit {
        if let p = caffeinateProcess, p.isRunning {
            p.terminate()
        }
    }
}

// MARK: - Performance Snapshot Service

public actor PerformanceSnapshotService {
    private let runner: any CommandRunning

    public init(runner: any CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    public func generateSnapshotReport(metalHUDOptions: MetalHUDOptions, activeApp: String? = nil) async -> String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateStr = formatter.string(from: now)

        var report = """
        # Mac 游戏工具箱 - 性能诊断快照报告 (Performance Snapshot)
        **生成时间**：\(dateStr)
        **目标应用**：\(activeApp ?? "全局环境 (Global Environment)")

        ---

        ## 1. 硬件与系统环境
        - **macOS 版本**：\(ProcessInfo.processInfo.operatingSystemVersionString)
        - **芯片架构**：Apple Silicon (\(ProcessInfo.processInfo.activeProcessorCount) Cores)
        - **物理内存**：\(ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024)) GB

        ---

        ## 2. Metal HUD 调优参数
        - **全局注入开关**：已开启 (MTL_HUD_ENABLED=1)
        - **渲染缩放比例**：\(String(format: "%.2f", metalHUDOptions.scale))
        - **图层不透明度**：\(Int(metalHUDOptions.opacity * 100))%
        - **屏幕方位**：\(metalHUDOptions.alignment)
        - **激活监控指标项 (\(metalHUDOptions.elements.count))**：\(metalHUDOptions.elements.isEmpty ? "全部默认指标" : metalHUDOptions.elements.joined(separator: ", "))
        - **着色器编译日志**：\(metalHUDOptions.shaderLogEnabled ? "已启用" : "未启用")
        - **编码器耗时追踪**：\(metalHUDOptions.encoderTimingEnabled ? "已启用" : "未启用")

        ---

        ## 3. 运行中的游戏与 Wine 兼容层进程
        """

        if let psResult = try? await runner.run("/bin/ps", arguments: ["-ax", "-o", "pid,ppid,command"]) {
            let lines = psResult.outputString.components(separatedBy: .newlines)
            let filtered = lines.filter { line in
                let l = line.lowercased()
                return l.contains("wine") || l.contains("crossover") || l.contains("whisky") || l.contains("steam") || l.contains("d3dmetal") || l.contains("game")
            }
            if filtered.isEmpty {
                report += "\n- 未检测到运行中的 Wine / 游戏进程。\n"
            } else {
                report += "\n```text\n"
                for l in filtered.prefix(15) {
                    report += "\(l)\n"
                }
                report += "```\n"
            }
        }

        report += """

        ---
        *由 Mac 游戏工具箱自动生成。可直接附于社区讨论或技术支持工单。*
        """
        return report
    }
}

