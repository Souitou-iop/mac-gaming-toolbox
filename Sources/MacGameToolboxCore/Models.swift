import Foundation

func coreText(_ chinese: String, _ english: String) -> String {
    guard let preferred = Locale.preferredLanguages.first else { return english }
    return Locale(identifier: preferred).language.languageCode == .chinese ? chinese : english
}

public enum TaskPhase: String, Codable, Sendable {
    case idle, awaitingAuthorization, running, succeeded, failed, cancelled
}

public struct TaskStatus: Equatable, Sendable {
    public var phase: TaskPhase
    public var message: String
    public var progress: Double?
    public var log: [String]

    public init(phase: TaskPhase = .idle, message: String = "", progress: Double? = nil, log: [String] = []) {
        self.phase = phase
        self.message = message
        self.progress = progress
        self.log = log
    }
}

public struct DiskVolume: Identifiable, Hashable, Sendable {
    public let id: String
    public let volumeUUID: String?
    public let name: String
    public let fileSystem: String
    public let mountPoint: String?
    public let size: UInt64
    public let wholeDisk: String
    public let isInternal: Bool

    public init(id: String, volumeUUID: String? = nil, name: String, fileSystem: String, mountPoint: String?, size: UInt64, wholeDisk: String, isInternal: Bool) {
        self.id = id
        self.volumeUUID = volumeUUID
        self.name = name
        self.fileSystem = fileSystem
        self.mountPoint = mountPoint
        self.size = size
        self.wholeDisk = wholeDisk
        self.isInternal = isInternal
    }
}

public struct DiskPreset: Codable, Hashable, Sendable {
    public var diskIdentifier: String
    public var volumeUUID: String?
    public var mountPath: String?

    public init(diskIdentifier: String, volumeUUID: String? = nil, mountPath: String? = nil) {
        self.diskIdentifier = diskIdentifier
        self.volumeUUID = volumeUUID
        self.mountPath = mountPath
    }
}

public struct HostnameBackup: Codable, Equatable, Sendable {
    public var computerName: String
    public var hostName: String
    public var localHostName: String

    public init(computerName: String, hostName: String, localHostName: String) {
        self.computerName = computerName
        self.hostName = hostName
        self.localHostName = localHostName
    }
}

public struct SystemProcess: Identifiable, Hashable, Sendable {
    public var id: Int32 { pid }
    public let pid: Int32
    public let parentPID: Int32
    public let command: String

    public init(pid: Int32, parentPID: Int32, command: String) {
        self.pid = pid
        self.parentPID = parentPID
        self.command = command
    }
}

public enum MetalHUDProcessCategory: String, Codable, Hashable, CaseIterable, Sendable {
    case launcher
    case wineRuntime
    case gameOrApp

    public var titleZh: String {
        switch self {
        case .launcher: return "游戏平台与启动器"
        case .wineRuntime: return "Wine 与兼容层服务"
        case .gameOrApp: return "运行中的游戏与应用"
        }
    }

    public var titleEn: String {
        switch self {
        case .launcher: return "Game Launchers & Platforms"
        case .wineRuntime: return "Wine & Runtime Services"
        case .gameOrApp: return "Running Games & Apps"
        }
    }

    public var iconName: String {
        switch self {
        case .launcher: return "arrow.triangle.2.circlepath.circle.fill"
        case .wineRuntime: return "gearshape.2.fill"
        case .gameOrApp: return "gamecontroller.fill"
        }
    }
}

public struct MetalHUDProcess: Identifiable, Hashable, Sendable, Codable {
    public var id: Int32 { pid }
    public let pid: Int32
    public let parentPID: Int32
    public let name: String
    public let command: String
    public let category: MetalHUDProcessCategory
    public let appBundlePath: String?
    public let reasonZh: String
    public let reasonEn: String

    public init(
        pid: Int32,
        parentPID: Int32,
        name: String,
        command: String,
        category: MetalHUDProcessCategory,
        appBundlePath: String? = nil,
        reasonZh: String,
        reasonEn: String
    ) {
        self.pid = pid
        self.parentPID = parentPID
        self.name = name
        self.command = command
        self.category = category
        self.appBundlePath = appBundlePath
        self.reasonZh = reasonZh
        self.reasonEn = reasonEn
    }
}

public struct RecentMetalHUDApp: Codable, Hashable, Identifiable, Sendable {
    public var path: String
    public var displayName: String
    public var id: String { path }

    public init(path: String, displayName: String) {
        self.path = path
        self.displayName = displayName
    }
}

public struct MetalHUDElement: Sendable, Equatable {
    public let raw: String
    public let zh: String
    public let en: String
    public let unitOrSampleZh: String
    public let unitOrSampleEn: String
    public let hintZh: String
    public let hintEn: String

    public init(
        raw: String,
        zh: String,
        en: String,
        unitOrSampleZh: String = "",
        unitOrSampleEn: String = "",
        hintZh: String,
        hintEn: String
    ) {
        self.raw = raw
        self.zh = zh
        self.en = en
        self.unitOrSampleZh = unitOrSampleZh
        self.unitOrSampleEn = unitOrSampleEn
        self.hintZh = hintZh
        self.hintEn = hintEn
    }

    public static let allElements: [MetalHUDElement] = [
        MetalHUDElement(raw: "device", zh: "设备", en: "Device",
                        unitOrSampleZh: "示例: Apple M2 Pro", unitOrSampleEn: "e.g. Apple M2 Pro",
                        hintZh: "显示当前使用的 Metal 设备名称。", hintEn: "Shows the name of the active MTLDevice."),
        MetalHUDElement(raw: "rosetta", zh: "Rosetta 信息", en: "Rosetta Info",
                        unitOrSampleZh: "示例: x86_64", unitOrSampleEn: "e.g. x86_64",
                        hintZh: "当 App 通过 Rosetta 转译运行时，显示活跃架构 (x86_64)。", hintEn: "Shows the active architecture (x86_64) if the app runs through the Rosetta translation layer."),
        MetalHUDElement(raw: "layersize", zh: "图层尺寸与合成", en: "Layer Size & Composition",
                        unitOrSampleZh: "示例: 2560×1440 (Direct)", unitOrSampleEn: "e.g. 2560×1440 (Direct)",
                        hintZh: "显示图层尺寸与呈现模式（直接或合成）。", hintEn: "Shows the size of the layer and the present mode (direct or composited)."),
        MetalHUDElement(raw: "layerscale", zh: "图层缩放与像素格式", en: "Layer Scale & Pixel Format",
                        unitOrSampleZh: "示例: 2.0x (BGRA8Unorm)", unitOrSampleEn: "e.g. 2.0x (BGRA8Unorm)",
                        hintZh: "显示图层内容缩放因子与像素格式。", hintEn: "Shows the content scale factor and pixel format of the layer."),
        MetalHUDElement(raw: "memory", zh: "内存", en: "Memory",
                        unitOrSampleZh: "单位: MB / GB (如 3.4 GB)", unitOrSampleEn: "Unit: MB / GB (e.g. 3.4 GB)",
                        hintZh: "显示进程当前内存使用量与 MTLDevice 的 currentAllocatedSize。", hintEn: "Shows current process memory usage and the currentAllocatedSize of the MTLDevice."),
        MetalHUDElement(raw: "refreshrate", zh: "屏幕刷新率", en: "Screen Refresh Rate",
                        unitOrSampleZh: "单位: Hz (如 120 Hz)", unitOrSampleEn: "Unit: Hz (e.g. 120 Hz)",
                        hintZh: "显示 App 所在屏幕的当前刷新率。", hintEn: "Shows the current refresh rate of the display your app is on."),
        MetalHUDElement(raw: "thermal", zh: "热状态", en: "Thermal State",
                        unitOrSampleZh: "状态: Nominal / Fair", unitOrSampleEn: "State: Nominal / Fair",
                        hintZh: "显示机器当前的 thermalState。", hintEn: "Shows the current thermalState of the machine."),
        MetalHUDElement(raw: "gamemode", zh: "游戏模式", en: "Game Mode",
                        unitOrSampleZh: "状态: ON / OFF", unitOrSampleEn: "State: ON / OFF",
                        hintZh: "显示游戏模式的开关状态。", hintEn: "Shows the state of Game Mode (on or off)."),
        MetalHUDElement(raw: "fps", zh: "FPS", en: "FPS",
                        unitOrSampleZh: "单位: FPS (如 60.0 FPS)", unitOrSampleEn: "Unit: FPS (e.g. 60.0 FPS)",
                        hintZh: "显示过去 120 帧每秒帧数的滚动平均值。", hintEn: "Rolling average of frames per second for the past 120 frames."),
        MetalHUDElement(raw: "fpsgraph", zh: "FPS 图表", en: "FPS Graph",
                        unitOrSampleZh: "单位: 120 帧折线图 (FPS)", unitOrSampleEn: "Unit: 120-frame Chart (FPS)",
                        hintZh: "以图表显示过去 120 帧的 FPS。", hintEn: "A chart graphing the FPS for the past 120 frames."),
        MetalHUDElement(raw: "framenumber", zh: "帧号", en: "Frame Number",
                        unitOrSampleZh: "单位: 累计呈现帧数 (如 #14280)", unitOrSampleEn: "Unit: Frame Index (e.g. #14280)",
                        hintZh: "显示当前帧号（自启动或上次重置以来的呈现次数，含插值帧）。", hintEn: "Current frame number. Counts interpolated frames when frame interpolation is enabled."),
        MetalHUDElement(raw: "gputime", zh: "GPU 时间", en: "GPU Time",
                        unitOrSampleZh: "单位: ms (毫秒，如 8.2 ms)", unitOrSampleEn: "Unit: ms (e.g. 8.2 ms)",
                        hintZh: "显示过去 120 帧 GPU 时间的滚动平均值（基于命令缓冲区 gpuStart/EndTime）。", hintEn: "Rolling average of GPU time for the past 120 frames, computed from command buffer gpuStartTime/gpuEndTime."),
        MetalHUDElement(raw: "presentdelay", zh: "呈现延迟", en: "Present Delay",
                        unitOrSampleZh: "单位: ms (延迟，如 2.1 ms)", unitOrSampleEn: "Unit: ms (e.g. 2.1 ms)",
                        hintZh: "显示过去 120 帧呈现延迟的滚动平均值（调用 presentDrawable 到上屏的间隔）。", hintEn: "Rolling average of present delay for the past 120 frames (interval from presentDrawable to display)."),
        MetalHUDElement(raw: "frameinterval", zh: "帧间隔", en: "Frame Interval",
                        unitOrSampleZh: "单位: ms (帧间隔，如 16.6 ms)", unitOrSampleEn: "Unit: ms (e.g. 16.6 ms)",
                        hintZh: "显示过去 120 帧两个连续 MTLDrawable 上屏时间差的滚动平均值。", hintEn: "Rolling average of the on-glass time difference between two consecutive MTLDrawables for the past 120 frames."),
        MetalHUDElement(raw: "frameintervalgraph", zh: "帧间隔图表", en: "Frame Interval Graph",
                        unitOrSampleZh: "单位: 120 帧波动图 (ms)", unitOrSampleEn: "Unit: 120-frame Graph (ms)",
                        hintZh: "以图表显示过去 120 帧的帧间隔。", hintEn: "A chart graphing the frame interval for the past 120 frames."),
        MetalHUDElement(raw: "frameintervalhistogram", zh: "帧间隔直方图", en: "Frame Interval Histogram",
                        unitOrSampleZh: "单位: 刷新率分桶直方图", unitOrSampleEn: "Unit: Bucketed Histogram",
                        hintZh: "以柱状图显示分桶帧间隔，桶大小为屏幕刷新率。", hintEn: "A bucketed frame interval bar chart. Bucket size is the display refresh rate."),
        MetalHUDElement(raw: "metalcpu", zh: "命令缓冲区与编码器数量", en: "Command Buffer & Encoder Count",
                        unitOrSampleZh: "单位: ms / 数量 (如 2.4 ms, 8 Buffers)", unitOrSampleEn: "Unit: ms / Count (e.g. 2.4 ms, 8 Buffers)",
                        hintZh: "显示上一帧调度到的命令缓冲区与编码器数量及 CPU 编码时间。", hintEn: "Number of scheduled command buffers and encoders, and their CPU encoding time for the last frame."),
        MetalHUDElement(raw: "gputimeline", zh: "编码器时间与 GPU 时间线", en: "Encoder Time & GPU Timeline",
                        unitOrSampleZh: "单位: 编码器 GPU 时间线图", unitOrSampleEn: "Unit: Encoder GPU Timeline",
                        hintZh: "显示各类编码器的 GPU 时间与 GPU 时间线图表（需开启编码器 GPU 时间追踪）。", hintEn: "Encoder GPU times per type and a GPU timeline graph. Requires encoder GPU time tracking."),
        MetalHUDElement(raw: "shaders", zh: "着色器编译器", en: "Shader Compiler",
                        unitOrSampleZh: "单位: 管线数 (如 12 Pipes, 0 Compiling)", unitOrSampleEn: "Unit: Pipelines (e.g. 12 Pipes, 0 Compiling)",
                        hintZh: "显示着色器编译活动：管线状态数、缓存着色器数、已编译着色器数与编译时间图表。", hintEn: "Shader compiler activity: pipeline state count, cached/compiled shader counts, and a compilation-time graph."),
        MetalHUDElement(raw: "disk", zh: "磁盘使用", en: "Disk Usage",
                        unitOrSampleZh: "单位: MB/s (如 R: 120 MB/s, W: 0 MB/s)", unitOrSampleEn: "Unit: MB/s (e.g. R: 120 MB/s, W: 0 MB/s)",
                        hintZh: "显示系统上报的磁盘读取、写入与逻辑写入字节数。", hintEn: "Disk bytes read, written, and logical writes as reported by system usage."),
        MetalHUDElement(raw: "toplabeledcommandbuffers", zh: "高占用命令缓冲区（含标记）", en: "Top Labeled Command Buffers",
                        unitOrSampleZh: "单位: 耗时 (如 ShadowPass: 3.2ms)", unitOrSampleEn: "Unit: Time (e.g. ShadowPass: 3.2ms)",
                        hintZh: "显示 GPU 占用最高且带 label 的命令缓冲区（需开启编码器 GPU 时间追踪）。", hintEn: "Most GPU-intensive labeled command buffers. Requires encoder GPU time tracking."),
        MetalHUDElement(raw: "toplabeledencoders", zh: "高占用编码器（含标记）", en: "Top Labeled Encoders",
                        unitOrSampleZh: "单位: 耗时 (如 DeferredLight: 2.8ms)", unitOrSampleEn: "Unit: Time (e.g. DeferredLight: 2.8ms)",
                        hintZh: "显示 GPU 占用最高且带 label 的编码器（需开启编码器 GPU 时间追踪）。", hintEn: "Most GPU-intensive labeled encoders. Requires encoder GPU time tracking."),
        MetalHUDElement(raw: "metalfx", zh: "MetalFX", en: "MetalFX",
                        unitOrSampleZh: "示例: 缩放模式 (1080p -> 4K)", unitOrSampleEn: "e.g. Upscaling (1080p -> 4K)",
                        hintZh: "显示 MetalFX 相关指标（属于瞬态指标，禁用 MetalFX 时自动隐藏）。", hintEn: "MetalFX metrics. Transient — automatically hidden when MetalFX is disabled.")
    ]
}

public struct MetalHUDOptions: Codable, Equatable, Sendable {
    public var opacity: Double = 1.0
    public var scale: Double = 0.2
    public var alignment: String = "topright"
    public var positionX: Int? = nil
    public var positionY: Int? = nil
    public var elements: [String] = []
    public var logEnabled: Bool = false
    public var shaderLogEnabled: Bool = false
    public var encoderTimingEnabled: Bool = false
    public var encoderGpuTimelineFrameCount: Int? = nil
    public var encoderGpuTimelineSwapDelta: Int? = nil
    public var showZeroMetrics: Bool = false
    public var showMetricsRange: Bool = false
    public var metricTimeout: Int? = nil
    public var insightsEnabled: Bool = false
    public var insightTimeout: Int? = nil
    public var insightReportInterval: Int? = nil
    public var rusageUpdateInterval: Int? = nil
    public var reportURL: String? = nil
    public var disableMenuBar: Bool = false
    public var configFilePath: String? = nil

    public init(
        opacity: Double = 1.0,
        scale: Double = 0.2,
        alignment: String = "topright",
        positionX: Int? = nil,
        positionY: Int? = nil,
        elements: [String] = [],
        logEnabled: Bool = false,
        shaderLogEnabled: Bool = false,
        encoderTimingEnabled: Bool = false,
        encoderGpuTimelineFrameCount: Int? = nil,
        encoderGpuTimelineSwapDelta: Int? = nil,
        showZeroMetrics: Bool = false,
        showMetricsRange: Bool = false,
        metricTimeout: Int? = nil,
        insightsEnabled: Bool = false,
        insightTimeout: Int? = nil,
        insightReportInterval: Int? = nil,
        rusageUpdateInterval: Int? = nil,
        reportURL: String? = nil,
        disableMenuBar: Bool = false,
        configFilePath: String? = nil
    ) {
        self.opacity = opacity
        self.scale = scale
        self.alignment = alignment
        self.positionX = positionX
        self.positionY = positionY
        self.elements = elements
        self.logEnabled = logEnabled
        self.shaderLogEnabled = shaderLogEnabled
        self.encoderTimingEnabled = encoderTimingEnabled
        self.encoderGpuTimelineFrameCount = encoderGpuTimelineFrameCount
        self.encoderGpuTimelineSwapDelta = encoderGpuTimelineSwapDelta
        self.showZeroMetrics = showZeroMetrics
        self.showMetricsRange = showMetricsRange
        self.metricTimeout = metricTimeout
        self.insightsEnabled = insightsEnabled
        self.insightTimeout = insightTimeout
        self.insightReportInterval = insightReportInterval
        self.rusageUpdateInterval = rusageUpdateInterval
        self.reportURL = reportURL
        self.disableMenuBar = disableMenuBar
        self.configFilePath = configFilePath
    }

    private enum CodingKeys: String, CodingKey {
        case opacity, scale, alignment, positionX, positionY, elements
        case logEnabled, shaderLogEnabled, encoderTimingEnabled
        case encoderGpuTimelineFrameCount, encoderGpuTimelineSwapDelta
        case showZeroMetrics, showMetricsRange, metricTimeout
        case insightsEnabled, insightTimeout, insightReportInterval, rusageUpdateInterval
        case reportURL, disableMenuBar, configFilePath
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
        scale = try container.decodeIfPresent(Double.self, forKey: .scale) ?? 0.2
        alignment = try container.decodeIfPresent(String.self, forKey: .alignment) ?? "topright"
        positionX = try container.decodeIfPresent(Int.self, forKey: .positionX)
        positionY = try container.decodeIfPresent(Int.self, forKey: .positionY)
        elements = try container.decodeIfPresent([String].self, forKey: .elements) ?? []
        logEnabled = try container.decodeIfPresent(Bool.self, forKey: .logEnabled) ?? false
        shaderLogEnabled = try container.decodeIfPresent(Bool.self, forKey: .shaderLogEnabled) ?? false
        encoderTimingEnabled = try container.decodeIfPresent(Bool.self, forKey: .encoderTimingEnabled) ?? false
        encoderGpuTimelineFrameCount = try container.decodeIfPresent(Int.self, forKey: .encoderGpuTimelineFrameCount)
        encoderGpuTimelineSwapDelta = try container.decodeIfPresent(Int.self, forKey: .encoderGpuTimelineSwapDelta)
        showZeroMetrics = try container.decodeIfPresent(Bool.self, forKey: .showZeroMetrics) ?? false
        showMetricsRange = try container.decodeIfPresent(Bool.self, forKey: .showMetricsRange) ?? false
        metricTimeout = try container.decodeIfPresent(Int.self, forKey: .metricTimeout)
        insightsEnabled = try container.decodeIfPresent(Bool.self, forKey: .insightsEnabled) ?? false
        insightTimeout = try container.decodeIfPresent(Int.self, forKey: .insightTimeout)
        insightReportInterval = try container.decodeIfPresent(Int.self, forKey: .insightReportInterval)
        rusageUpdateInterval = try container.decodeIfPresent(Int.self, forKey: .rusageUpdateInterval)
        reportURL = try container.decodeIfPresent(String.self, forKey: .reportURL)
        disableMenuBar = try container.decodeIfPresent(Bool.self, forKey: .disableMenuBar) ?? false
        configFilePath = try container.decodeIfPresent(String.self, forKey: .configFilePath)
    }
}

public enum NavigationCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case overview
    case metalHUD
    case gameBoost
    case storage
    case system
    case about

    public var id: String { rawValue }

    public var titleZh: String {
        switch self {
        case .overview: return "概览与状态"
        case .metalHUD: return "Metal HUD 调优"
        case .gameBoost: return "游戏加速与启动"
        case .storage: return "存储与磁盘"
        case .system: return "系统与偏好"
        case .about: return "关于与致谢"
        }
    }

    public var titleEn: String {
        switch self {
        case .overview: return "Overview"
        case .metalHUD: return "Metal HUD Tuner"
        case .gameBoost: return "Game Boost"
        case .storage: return "Storage & Disks"
        case .system: return "System & Tools"
        case .about: return "About & Thanks"
        }
    }

    public var iconName: String {
        switch self {
        case .overview: return "gauge.with.dots.needle.67percent"
        case .metalHUD: return "chart.xyaxis.line"
        case .gameBoost: return "bolt.fill"
        case .storage: return "externaldrive.fill"
        case .system: return "gearshape.2.fill"
        case .about: return "info.circle.fill"
        }
    }
}

public enum NavigationLayoutMode: String, Codable, CaseIterable, Sendable {
    case sidebar
    case commandCenter

    public var titleZh: String {
        switch self {
        case .sidebar: return "侧边栏模式"
        case .commandCenter: return "控制台模式"
        }
    }

    public var titleEn: String {
        switch self {
        case .sidebar: return "Sidebar View"
        case .commandCenter: return "Command Center"
        }
    }

    public var iconName: String {
        switch self {
        case .sidebar: return "sidebar.left"
        case .commandCenter: return "rectangle.grid.2x2.fill"
        }
    }
}

public struct AppConfiguration: Codable, Equatable, Sendable {
    public var schemaVersion = 3
    public var didImportLegacyConfiguration = false
    public var defaultPaths: [String] = []
    public var diskPresets: [DiskPreset] = []
    public var automaticallyRestoreMountsOnLaunch = false
    public var restorableDiskMounts: [DiskPreset] = []
    public var hostnameBackup: HostnameBackup?
    public var customWallpaperPath: String?
    public var recentMetalHUDApps: [RecentMetalHUDApp] = []
    public var hoYoWaitSeconds = 15
    public var excludesSensitiveCacheFiles = true
    public var metalHUDOptions = MetalHUDOptions()
    public var navigationLayoutMode: NavigationLayoutMode = .sidebar

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, didImportLegacyConfiguration, defaultPaths, diskPresets
        case automaticallyRestoreMountsOnLaunch, restorableDiskMounts, hostnameBackup, customWallpaperPath
        case recentMetalHUDApps, hoYoWaitSeconds, excludesSensitiveCacheFiles, metalHUDOptions, navigationLayoutMode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        didImportLegacyConfiguration = try container.decodeIfPresent(Bool.self, forKey: .didImportLegacyConfiguration) ?? false
        defaultPaths = try container.decodeIfPresent([String].self, forKey: .defaultPaths) ?? []
        diskPresets = try container.decodeIfPresent([DiskPreset].self, forKey: .diskPresets) ?? []
        automaticallyRestoreMountsOnLaunch = try container.decodeIfPresent(Bool.self, forKey: .automaticallyRestoreMountsOnLaunch) ?? false
        restorableDiskMounts = try container.decodeIfPresent([DiskPreset].self, forKey: .restorableDiskMounts) ?? []
        hostnameBackup = try container.decodeIfPresent(HostnameBackup.self, forKey: .hostnameBackup)
        customWallpaperPath = try container.decodeIfPresent(String.self, forKey: .customWallpaperPath)
        recentMetalHUDApps = try container.decodeIfPresent([RecentMetalHUDApp].self, forKey: .recentMetalHUDApps) ?? []
        let decodedWait = try container.decodeIfPresent(Int.self, forKey: .hoYoWaitSeconds) ?? 15
        hoYoWaitSeconds = [10, 15, 20].contains(decodedWait) ? decodedWait : 15
        excludesSensitiveCacheFiles = try container.decodeIfPresent(Bool.self, forKey: .excludesSensitiveCacheFiles) ?? true
        metalHUDOptions = try container.decodeIfPresent(MetalHUDOptions.self, forKey: .metalHUDOptions) ?? MetalHUDOptions()
        navigationLayoutMode = try container.decodeIfPresent(NavigationLayoutMode.self, forKey: .navigationLayoutMode) ?? .sidebar
    }
}

public enum ToolboxError: LocalizedError, Equatable {
    case invalidPath(String)
    case invalidDisk(String)
    case commandFailed(String)
    case authorizationCancelled
    case helperApprovalRequired
    case helperUnavailable(String)
    case helperTimedOut
    case malformedOutput(String)

    public var errorDescription: String? {
        switch self {
        case .invalidPath(let path): coreText("无效路径：\(path)", "Invalid path: \(path)")
        case .invalidDisk(let disk): coreText("无效磁盘：\(disk)", "Invalid disk: \(disk)")
        case .commandFailed(let message): message
        case .authorizationCancelled: coreText("已取消管理员授权", "Authorization cancelled")
        case .helperApprovalRequired: coreText("辅助服务需要在系统设置的“登录项与扩展”中批准", "Approve the helper in System Settings > Login Items & Extensions")
        case .helperUnavailable(let message): coreText("辅助服务不可用：\(message)", "Privileged helper unavailable: \(message)")
        case .helperTimedOut: coreText("辅助服务响应超时", "Privileged helper timed out")
        case .malformedOutput(let message): coreText("无法解析系统输出：\(message)", "Invalid system output: \(message)")
        }
    }
}
