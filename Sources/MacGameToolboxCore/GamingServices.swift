import Foundation

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
