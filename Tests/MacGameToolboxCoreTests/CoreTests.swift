import Foundation
import Testing
@testable import MacGameToolboxCore

@Test func pathValidationNormalizesAndRejectsRoot() throws {
    #expect(try InputValidation.normalizedAbsolutePath("~/Games", home: "/Users/test") == "/Users/test/Games")
    #expect(throws: ToolboxError.invalidPath("/")) { try InputValidation.normalizedAbsolutePath("/") }
    #expect(InputValidation.diskIdentifier("disk12s3"))
    #expect(!InputValidation.diskIdentifier("disk0"))
}

@Test func legacyConfigurationImportsValues() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let configURL = root.appendingPathComponent("new/configuration.json")
    let defaultDirectory = root.appendingPathComponent("Library/Disk Setup")
    let presetDirectory = root.appendingPathComponent("Library/Application Support/DiskUtilHelper")
    try FileManager.default.createDirectory(at: defaultDirectory, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: presetDirectory, withIntermediateDirectories: true)
    try "/tmp/a\n/tmp/b\n/tmp/a\n/tmp/c\n/tmp/d\n".write(to: defaultDirectory.appendingPathComponent("default_paths.txt"), atomically: true, encoding: .utf8)
    try "disk2s1\ndisk3s1\ninvalid\n".write(to: presetDirectory.appendingPathComponent("presetDiskIdentifiers.txt"), atomically: true, encoding: .utf8)
    try "disk2s1:/tmp/game:bottle\n".write(to: presetDirectory.appendingPathComponent("presetMappings.txt"), atomically: true, encoding: .utf8)

    let store = ConfigurationStore(configurationURL: configURL)
    let configuration = try await store.load(homeURL: root)
    #expect(configuration.didImportLegacyConfiguration)
    #expect(configuration.defaultPaths == ["/tmp/a", "/tmp/b", "/tmp/c", "/tmp/d"])
    #expect(configuration.diskPresets.count == 2)
    #expect(configuration.diskPresets.first?.mountPath == "/tmp/game:bottle")
}

@Test func diskParserExcludesBootDisk() throws {
    let plist: [String: Any] = [
        "AllDisksAndPartitions": [
            ["DeviceIdentifier": "disk0", "Partitions": [["DeviceIdentifier": "disk0s1", "VolumeName": "System", "Size": 10]]],
            ["DeviceIdentifier": "disk4", "Internal": false, "Partitions": [["DeviceIdentifier": "disk4s2", "Content": "Apple_APFS", "APFSVolumes": [["DeviceIdentifier": "disk5s1", "VolumeName": "Games", "Content": "APFS", "MountPoint": "/Volumes/Games", "Size": 1234]]]]]
        ]
    ]
    let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    let volumes = try DiskService.parseVolumes(data, excludingWholeDisk: "disk0")
    #expect(volumes.map(\.id) == ["disk5s1"])
    #expect(volumes.first?.mountPoint == "/Volumes/Games")
}

@Test func configurationRoundTripsHostnameBackupAndSpecialPaths() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = ConfigurationStore(configurationURL: root.appendingPathComponent("configuration.json"))
    var configuration = AppConfiguration()
    configuration.defaultPaths = ["/tmp/Game Bottle's Data"]
    configuration.hostnameBackup = HostnameBackup(computerName: "Iven Mac", hostName: "iven-mac", localHostName: "iven-mac")
    try await store.save(configuration)
    let loaded = try await store.load(importLegacy: false)
    #expect(loaded == configuration)
    #expect(try InputValidation.normalizedAbsolutePath("/tmp/Game Bottle's Data") == "/tmp/Game Bottle's Data")
}

@Test func olderConfigurationDefaultsAutomaticMountRestorationToOff() throws {
    let data = Data(#"{"schemaVersion":1,"diskPresets":[{"diskIdentifier":"disk4s1","mountPath":"/tmp/Games"}]}"#.utf8)
    let configuration = try JSONDecoder().decode(AppConfiguration.self, from: data)
    #expect(!configuration.automaticallyRestoreMountsOnLaunch)
    #expect(configuration.restorableDiskMounts.isEmpty)
    #expect(configuration.recentMetalHUDApps.isEmpty)
    #expect(configuration.hoYoWaitSeconds == 15)
    #expect(configuration.excludesSensitiveCacheFiles)
    #expect(configuration.diskPresets.first?.diskIdentifier == "disk4s1")
}

@Test func configurationRoundTripsAutomaticMountRestorationState() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = ConfigurationStore(configurationURL: root.appendingPathComponent("configuration.json"))
    var configuration = AppConfiguration()
    configuration.automaticallyRestoreMountsOnLaunch = true
    configuration.restorableDiskMounts = [DiskPreset(diskIdentifier: "disk8s1", mountPath: "/tmp/Games")]
    try await store.save(configuration)
    let loaded = try await store.load(importLegacy: false)
    #expect(loaded.automaticallyRestoreMountsOnLaunch)
    #expect(loaded.restorableDiskMounts == configuration.restorableDiskMounts)
    #expect(loaded.schemaVersion == 3)
}

@Test func configurationPreservesAllRestorableMounts() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = ConfigurationStore(configurationURL: root.appendingPathComponent("configuration.json"))
    var configuration = AppConfiguration()
    configuration.restorableDiskMounts = (1...1_000).map {
        DiskPreset(diskIdentifier: "disk\($0)s1", mountPath: "/tmp/Games-\($0)")
    }

    try await store.save(configuration)
    let loaded = try await store.load(importLegacy: false)

    #expect(DiskService.maximumBatchMounts == Int.max)
    #expect(loaded.restorableDiskMounts.count == configuration.restorableDiskMounts.count)
    #expect(loaded.restorableDiskMounts.first?.diskIdentifier == "disk1s1")
    #expect(loaded.restorableDiskMounts.last?.diskIdentifier == "disk1000s1")
}

@Test func configurationPreservesAllDefaultPaths() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = ConfigurationStore(configurationURL: root.appendingPathComponent("configuration.json"))
    var configuration = AppConfiguration()
    configuration.defaultPaths = (1...1_000).map { "/tmp/Games-\($0)" }

    try await store.save(configuration)
    let loaded = try await store.load(importLegacy: false)

    #expect(ConfigurationStore.maxDefaultPaths == Int.max)
    #expect(loaded.defaultPaths.count == configuration.defaultPaths.count)
    #expect(loaded.defaultPaths.first == "/tmp/Games-1")
    #expect(loaded.defaultPaths.last == "/tmp/Games-1000")
}

@Test func automaticMountMatchingPrefersStableVolumeUUIDAndFallsBackToIdentifier() {
    let oldIdentifier = DiskPreset(diskIdentifier: "disk4s1", volumeUUID: "VOLUME-UUID", mountPath: "/tmp/Games")
    let renumberedVolume = DiskVolume(id: "disk8s2", volumeUUID: "volume-uuid", name: "Games", fileSystem: "apfs", mountPoint: nil, size: 1, wholeDisk: "disk8", isInternal: false)
    #expect(DiskService.matchingVolume(for: oldIdentifier, in: [renumberedVolume])?.id == "disk8s2")

    let legacyPreset = DiskPreset(diskIdentifier: "disk4s1", mountPath: "/tmp/Games")
    let legacyVolume = DiskVolume(id: "disk4s1", name: "Games", fileSystem: "apfs", mountPoint: nil, size: 1, wholeDisk: "disk4", isInternal: false)
    #expect(DiskService.matchingVolume(for: legacyPreset, in: [legacyVolume])?.id == "disk4s1")
}

@Test func hostsEditorIsIdempotentAndRollsBack() {
    let original = "127.0.0.1 localhost\n0.0.0.0 example.com\n"
    let domains = ["a.example", "b.example"]
    let enabled = HostsFileEditor.replacingManagedBlock(in: original, domains: domains, enabled: true)
    #expect(HostsFileEditor.replacingManagedBlock(in: enabled, domains: domains, enabled: true) == enabled)
    #expect(HostsFileEditor.replacingManagedBlock(in: enabled, domains: domains, enabled: false) == original)
}

@Test func hoYoDomainsIncludeAllLaunchAssistanceEndpoints() {
    let expectedDomains = [
        "globaldp-prod-cn01.juequling.com",
        "globaldp-prod-cn02.juequling.com",
        "globaldp-prod-os01.zenlesszonezero.com",
        "globaldp-prod-os02.zenlesszonezero.com",
    ]
    #expect(expectedDomains.allSatisfy(GamingService.hoyoDomains.contains))
}

@Test func processParserFiltersCrossOver() {
    let text = "  100 1 /Applications/CrossOver 25.app/Contents/MacOS/CrossOver\n  110 100 /Applications/CrossOver 25.app/Contents/SharedSupport/CrossOver/bin/cxoffice\n  120 110 /Applications/CrossOver 25.app/Contents/SharedSupport/CrossOver/bin/wine64-preloader\n  200 1 /usr/local/bin/wine game.exe\n  300 1 unrelated"
    let processes = GamingService.parseProcessTable(text)
    #expect(GamingService.matchingProcesses(processes, crossOverOnly: false).map(\.pid) == [120, 200])
    #expect(GamingService.matchingProcesses(processes, crossOverOnly: true).map(\.pid) == [100, 110, 120])
}

@Test func processParserFindsDetachedCrossOverWineServices() {
    let text = "  3949 1 C:\\windows\\system32\\winedevice.exe\n  3950 1 C:\\windows\\system32\\wineserver.exe"
    let processes = GamingService.parseProcessTable(text)
    #expect(GamingService.matchingProcesses(processes, crossOverOnly: true).map(\.pid) == [3949, 3950])
}

@Test func volumeInfoFilteringUsesPhysicalBootStoresAndKeepsUnmountedExternalVolumes() {
    let boot: [String: Any] = [
        "ParentWholeDisk": "disk3",
        "DeviceIdentifier": "disk3s3s1",
        "BooterDeviceIdentifier": "disk3s4",
        "RecoveryDeviceIdentifier": "disk3s5",
        "APFSVolumeGroupID": "SYSTEM-GROUP",
        "APFSPhysicalStores": [["APFSPhysicalStore": "disk0s2"]]
    ]
    let excluded = DiskService.systemWholeDisks(from: boot)
    #expect(excluded == ["disk0", "disk3"])

    let external: [String: Any] = [
        "DeviceIdentifier": "disk8s1", "ParentWholeDisk": "disk8", "WholeDisk": false,
        "VolumeName": "Games", "FilesystemType": "exfat", "MountPoint": "", "TotalSize": 2_000,
        "Internal": false
    ]
    #expect(DiskService.parseVolumeInfo(external, bootInfo: boot)?.id == "disk8s1")

    var system = external
    system["DeviceIdentifier"] = "disk3s7"
    system["ParentWholeDisk"] = "disk3"
    system["APFSVolumeGroupID"] = "USER-CREATED-GROUP"
    #expect(DiskService.parseVolumeInfo(system, bootInfo: boot)?.id == "disk3s7")

    var systemGroupVolume = system
    systemGroupVolume["APFSVolumeGroupID"] = "SYSTEM-GROUP"
    #expect(DiskService.parseVolumeInfo(systemGroupVolume, bootInfo: boot) == nil)

    var cryptex = external
    cryptex["MountPoint"] = "/private/var/run/com.apple.security.cryptexd/mnt/toolchain"
    #expect(DiskService.parseVolumeInfo(cryptex, bootInfo: boot) == nil)
}

actor RecordingPrivilegedOperator: PrivilegedOperating {
    private(set) var operations: [PrivilegedOperation] = []
    func perform(_ operation: PrivilegedOperation) async throws { operations.append(operation) }
}

actor RecordingCommandRunner: CommandRunning {
    private(set) var calls: [(String, [String])] = []

    func run(_ executable: String, arguments: [String]) async throws -> CommandResult {
        calls.append((executable, arguments))
        return CommandResult(exitCode: 0, standardOutput: Data(), standardError: Data())
    }
}

@Test func perAppMetalHUDLaunchUsesScopedEnvironment() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let application = root.appendingPathComponent("Example Game.app", isDirectory: true)
    try FileManager.default.createDirectory(at: application, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let runner = RecordingCommandRunner()
    let service = GamingService(runner: runner, privileged: RecordingPrivilegedOperator())
    try await service.launchWithMetalHUD(applicationPath: application.path)

    let calls = await runner.calls
    #expect(calls.count == 1)
    #expect(calls.first?.0 == "/usr/bin/open")
    #expect(calls.first?.1 == ["-a", application.path, "--env", "MTL_HUD_ENABLED=1"])
}

@Test func metalHUDOptionsRoundTripAndClampsOpacity() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = ConfigurationStore(configurationURL: root.appendingPathComponent("configuration.json"))
    var configuration = AppConfiguration()
    configuration.metalHUDOptions = MetalHUDOptions(
        opacity: 1.5,
        scale: 1.4,
        alignment: "bogus",
        positionX: -10,
        positionY: 20,
        elements: ["fps", "gputime", "fps", ""],
        logEnabled: true,
        shaderLogEnabled: true,
        encoderGpuTimelineFrameCount: -2,
        metricTimeout: -5,
        reportURL: "",
        configFilePath: ""
    )
    try await store.save(configuration)
    let loaded = try await store.load(importLegacy: false)
    #expect(loaded.metalHUDOptions.opacity == 1.0)
    #expect(loaded.metalHUDOptions.scale == 1.0)
    #expect(loaded.metalHUDOptions.alignment == "topright")
    #expect(loaded.metalHUDOptions.positionX == nil)
    #expect(loaded.metalHUDOptions.positionY == 20)
    #expect(loaded.metalHUDOptions.elements == ["fps", "gputime"])
    #expect(loaded.metalHUDOptions.logEnabled)
    #expect(loaded.metalHUDOptions.shaderLogEnabled)
    #expect(loaded.metalHUDOptions.encoderGpuTimelineFrameCount == nil)
    #expect(loaded.metalHUDOptions.metricTimeout == nil)
    #expect(loaded.metalHUDOptions.configFilePath == nil)
    #expect(loaded.metalHUDOptions.reportURL == nil)
}

@Test func metalHUDOptionsDefaultsWhenMissing() throws {
    let data = Data(#"{"schemaVersion":3}"#.utf8)
    let configuration = try JSONDecoder().decode(AppConfiguration.self, from: data)
    #expect(configuration.metalHUDOptions == MetalHUDOptions())
    #expect(configuration.metalHUDOptions.opacity == 1.0)
    #expect(configuration.metalHUDOptions.scale == 0.2)
    #expect(configuration.metalHUDOptions.alignment == "topright")
    #expect(configuration.metalHUDOptions.positionX == nil)
    #expect(configuration.metalHUDOptions.positionY == nil)
    #expect(configuration.metalHUDOptions.elements.isEmpty)
    #expect(!configuration.metalHUDOptions.logEnabled)
    #expect(!configuration.metalHUDOptions.shaderLogEnabled)
    #expect(!configuration.metalHUDOptions.encoderTimingEnabled)
    #expect(configuration.metalHUDOptions.encoderGpuTimelineFrameCount == nil)
    #expect(configuration.metalHUDOptions.encoderGpuTimelineSwapDelta == nil)
    #expect(!configuration.metalHUDOptions.showZeroMetrics)
    #expect(!configuration.metalHUDOptions.showMetricsRange)
    #expect(configuration.metalHUDOptions.metricTimeout == nil)
    #expect(!configuration.metalHUDOptions.insightsEnabled)
    #expect(configuration.metalHUDOptions.insightTimeout == nil)
    #expect(configuration.metalHUDOptions.insightReportInterval == nil)
    #expect(configuration.metalHUDOptions.rusageUpdateInterval == nil)
    #expect(configuration.metalHUDOptions.reportURL == nil)
    #expect(!configuration.metalHUDOptions.disableMenuBar)
    #expect(configuration.metalHUDOptions.configFilePath == nil)
}

@Test func perAppMetalHUDLaunchInjectsOptions() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let application = root.appendingPathComponent("Example Game.app", isDirectory: true)
    try FileManager.default.createDirectory(at: application, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let runner = RecordingCommandRunner()
    let service = GamingService(runner: runner, privileged: RecordingPrivilegedOperator())
    try await service.launchWithMetalHUD(
        applicationPath: application.path,
        options: MetalHUDOptions(
            opacity: 0.6,
            scale: 0.3,
            alignment: "bottomleft",
            elements: ["fps", "gputime"],
            logEnabled: true,
            shaderLogEnabled: false,
            encoderTimingEnabled: true,
            encoderGpuTimelineFrameCount: 8,
            insightsEnabled: true,
            disableMenuBar: true
        )
    )

    let calls = await runner.calls
    #expect(calls.count == 1)
    let arguments = try #require(calls.first?.1)
    #expect(arguments.contains("MTL_HUD_ENABLED=1"))
    #expect(arguments.contains("MTL_HUD_OPACITY=0.6"))
    #expect(arguments.contains("MTL_HUD_SCALE=0.3"))
    #expect(arguments.contains("MTL_HUD_ALIGNMENT=bottomleft"))
    #expect(arguments.contains("MTL_HUD_ELEMENTS=fps,gputime"))
    #expect(arguments.contains("MTL_HUD_LOG_ENABLED=1"))
    #expect(arguments.contains("MTL_HUD_ENCODER_TIMING_ENABLED=1"))
    #expect(arguments.contains("MTL_HUD_INSIGHTS_ENABLED=1"))
    #expect(arguments.contains("MTL_HUD_DISABLE_MENU_BAR=1"))
    #expect(arguments.contains("MTL_HUD_ENCODER_GPU_TIMELINE_FRAME_COUNT=8"))
    #expect(!arguments.contains(where: { $0.hasPrefix("MTL_HUD_LOG_SHADER_ENABLED=") }))
    #expect(!arguments.contains(where: { $0.hasPrefix("MTL_HUD_POSITION_X=") }))
    #expect(!arguments.contains(where: { $0.hasPrefix("MTL_HUD_METRIC_TIMEOUT=") }))
}

@Test func perAppMetalHUDLaunchDefaultsInjectsOnlyEnabled() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let application = root.appendingPathComponent("Example Game.app", isDirectory: true)
    try FileManager.default.createDirectory(at: application, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let runner = RecordingCommandRunner()
    let service = GamingService(runner: runner, privileged: RecordingPrivilegedOperator())
    try await service.launchWithMetalHUD(applicationPath: application.path, options: MetalHUDOptions())

    let calls = await runner.calls
    #expect(calls.count == 1)
    #expect(calls.first?.0 == "/usr/bin/open")
    #expect(calls.first?.1 == ["-a", application.path, "--env", "MTL_HUD_ENABLED=1"])
}

@Test func globalSetMetalHUDClearsUnusedKeysAndSetsSpecifiedOptions() async throws {
    let runner = RecordingCommandRunner()
    let service = GamingService(runner: runner, privileged: RecordingPrivilegedOperator())
    let options = MetalHUDOptions(
        opacity: 0.8,
        scale: 0.3,
        alignment: "topleft",
        elements: ["fps", "gputime"]
    )
    try await service.setMetalHUD(enabled: true, options: options)

    let calls = await runner.calls
    #expect(calls.contains(where: { $0.0 == "/bin/launchctl" && $0.1 == ["setenv", "MTL_HUD_ENABLED", "1"] }))
    #expect(calls.contains(where: { $0.0 == "/bin/launchctl" && $0.1 == ["setenv", "MTL_HUD_OPACITY", "0.8"] }))
    #expect(calls.contains(where: { $0.0 == "/bin/launchctl" && $0.1 == ["setenv", "MTL_HUD_SCALE", "0.3"] }))
    #expect(calls.contains(where: { $0.0 == "/bin/launchctl" && $0.1 == ["setenv", "MTL_HUD_ALIGNMENT", "topleft"] }))
    #expect(calls.contains(where: { $0.0 == "/bin/launchctl" && $0.1 == ["setenv", "MTL_HUD_ELEMENTS", "fps,gputime"] }))
    // Keys not specified should be unset
    #expect(calls.contains(where: { $0.0 == "/bin/launchctl" && $0.1 == ["unsetenv", "MTL_HUD_POSITION_X"] }))
    #expect(calls.contains(where: { $0.0 == "/bin/launchctl" && $0.1 == ["unsetenv", "MTL_HUD_LOG_ENABLED"] }))
}

@Test func globalSetMetalHUDDisabledUnsetsAllKeys() async throws {
    let runner = RecordingCommandRunner()
    let service = GamingService(runner: runner, privileged: RecordingPrivilegedOperator())
    try await service.setMetalHUD(enabled: false)

    let calls = await runner.calls
    #expect(calls.contains(where: { $0.0 == "/bin/launchctl" && $0.1 == ["unsetenv", "MTL_HUD_ENABLED"] }))
    #expect(calls.contains(where: { $0.0 == "/bin/launchctl" && $0.1 == ["unsetenv", "MTL_HUD_OPACITY"] }))
    #expect(calls.contains(where: { $0.0 == "/bin/launchctl" && $0.1 == ["unsetenv", "MTL_HUD_SCALE"] }))
    #expect(calls.contains(where: { $0.0 == "/bin/launchctl" && $0.1 == ["unsetenv", "MTL_HUD_ALIGNMENT"] }))
    #expect(calls.contains(where: { $0.0 == "/bin/launchctl" && $0.1 == ["unsetenv", "MTL_HUD_ELEMENTS"] }))
}

@Test func identifyInterferingProcessesCategorizesLaunchersAndWineAndGames() {
    let processes = [
        SystemProcess(pid: 100, parentPID: 1, command: "/Applications/Steam.app/Contents/MacOS/steam_osx"),
        SystemProcess(pid: 101, parentPID: 1, command: "/Applications/CrossOver.app/Contents/MacOS/CrossOver"),
        SystemProcess(pid: 102, parentPID: 1, command: "/Applications/Whisky.app/Contents/MacOS/Whisky"),
        SystemProcess(pid: 103, parentPID: 1, command: "/Applications/Heroic.app/Contents/MacOS/Heroic"),
        SystemProcess(pid: 200, parentPID: 101, command: "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wineserver -p"),
        SystemProcess(pid: 201, parentPID: 200, command: "C:\\windows\\system32\\winedevice.exe"),
        SystemProcess(pid: 300, parentPID: 100, command: "/Users/demo/Library/Application Support/Steam/steamapps/common/MiSide/MiSide.exe"),
        SystemProcess(pid: 400, parentPID: 1, command: "/Applications/Hades.app/Contents/MacOS/Hades"),
        SystemProcess(pid: 999, parentPID: 1, command: "/Applications/Xcode.app/Contents/MacOS/Xcode"),
        SystemProcess(pid: 998, parentPID: 1, command: "/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder"),
        SystemProcess(pid: 997, parentPID: 1, command: "/usr/bin/login")
    ]

    let results = GamingService.identifyInterferingProcesses(processes, recentAppPaths: ["/Applications/Hades.app"])

    let steam = results.first { $0.pid == 100 }
    #expect(steam?.name == "Steam")
    #expect(steam?.category == .launcher)

    let crossover = results.first { $0.pid == 101 }
    #expect(crossover?.name == "CrossOver")
    #expect(crossover?.category == .launcher)

    let whisky = results.first { $0.pid == 102 }
    #expect(whisky?.name == "Whisky")
    #expect(whisky?.category == .launcher)

    let heroic = results.first { $0.pid == 103 }
    #expect(heroic?.name == "Heroic Games Launcher")
    #expect(heroic?.category == .launcher)

    let wineserver = results.first { $0.pid == 200 }
    #expect(wineserver?.category == .wineRuntime)

    let winedevice = results.first { $0.pid == 201 }
    #expect(winedevice?.category == .wineRuntime)

    let miside = results.first { $0.pid == 300 }
    #expect(miside?.category == .gameOrApp)

    let hades = results.first { $0.pid == 400 }
    #expect(hades?.category == .gameOrApp)

    // System and Dev tools should be excluded
    let pids = Set(results.map(\.pid))
    #expect(!pids.contains(999))
    #expect(!pids.contains(998))
    #expect(!pids.contains(997))
}

@Test func terminateProcessesSendsSignalsViaRunner() async throws {
    let runner = RecordingCommandRunner()
    let service = GamingService(runner: runner, privileged: RecordingPrivilegedOperator())

    let result = await service.terminateProcesses(pids: [1234, 5678], force: false)
    #expect(result.succeeded == [1234, 5678])

    let calls = await runner.calls
    #expect(calls.contains(where: { $0.0 == "/bin/kill" && $0.1 == ["-15", "1234"] }))
    #expect(calls.contains(where: { $0.0 == "/bin/kill" && $0.1 == ["-15", "5678"] }))

    _ = await service.terminateProcess(pid: 9999, force: true)
    let updatedCalls = await runner.calls
    #expect(updatedCalls.contains(where: { $0.0 == "/bin/kill" && $0.1 == ["-9", "9999"] }))
}

actor HostnameRunner: CommandRunning {
    func run(_ executable: String, arguments: [String]) async throws -> CommandResult {
        switch arguments.last {
        case "ComputerName": return CommandResult(exitCode: 0, standardOutput: Data("MacBook Pro\n".utf8), standardError: Data())
        case "LocalHostName": return CommandResult(exitCode: 0, standardOutput: Data("MacBook-Pro\n".utf8), standardError: Data())
        case "HostName": throw ToolboxError.commandFailed("HostName: not set")
        default: throw ToolboxError.commandFailed("unexpected fixture")
        }
    }
}

@Test func missingHostNameFallsBackToLocalHostName() async throws {
    let service = HostnameService(runner: HostnameRunner(), privileged: RecordingPrivilegedOperator())
    let names = try await service.current()
    #expect(names == HostnameBackup(computerName: "MacBook Pro", hostName: "MacBook-Pro", localHostName: "MacBook-Pro"))
    #expect(InputValidation.computerName(names.computerName))
}

@Test func privilegedHealthCheckRoundTripsThroughCodableRequest() throws {
    let data = try JSONEncoder().encode(PrivilegedRequest.healthCheck)
    let decoded = try JSONDecoder().decode(PrivilegedRequest.self, from: data)
    guard case .healthCheck = decoded else {
        Issue.record("Unexpected request case")
        return
    }
}

@Test func allPrivilegedRequestsRoundTripThroughCodable() throws {
    let requests: [PrivilegedRequest] = [
        .healthCheck,
        .addHoYoHosts,
        .removeHoYoHosts,
        .renice([42, 84]),
        .clearSystemCaches,
        .setHostnames(HostnameBackup(computerName: "steamdeck", hostName: "steamdeck", localHostName: "steamdeck")),
        .createDirectory("/Users/test/Games")
    ]
    for request in requests {
        let data = try JSONEncoder().encode(request)
        #expect(try JSONDecoder().decode(PrivilegedRequest.self, from: data) == request)
    }
}

@Test func helperRegistrationStatesChooseExpectedActions() {
    #expect(helperRegistrationDecision(for: .enabled) == .connect)
    #expect(helperRegistrationDecision(for: .notRegistered) == .register)
    #expect(helperRegistrationDecision(for: .requiresApproval) == .requestApproval)
    #expect(helperRegistrationDecision(for: .notFound) == .unavailable)
}

actor RejectingPrivilegedOperator: PrivilegedOperating {
    private(set) var operations: [PrivilegedOperation] = []
    func perform(_ operation: PrivilegedOperation) async throws {
        operations.append(operation)
        throw ToolboxError.authorizationCancelled
    }
}

@Test func cacheClearAuthorizesBeforeDeletingUserFiles() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let file = root.appendingPathComponent("keep-me.cache")
    try Data("important".utf8).write(to: file)
    defer { try? FileManager.default.removeItem(at: root) }

    let privileged = RejectingPrivilegedOperator()
    let service = CacheService(privileged: privileged)
    do {
        try await service.clear(CacheScan(userTargets: [root], systemTargets: [URL(fileURLWithPath: "/Library/Caches")], estimatedBytes: 9))
        Issue.record("Expected authorization failure")
    } catch {
        #expect(error as? ToolboxError == .authorizationCancelled)
    }
    #expect(FileManager.default.fileExists(atPath: file.path))
    #expect(await privileged.operations == [.healthCheck])
}

@Test func sensitiveCacheExclusionScansAndClearsOnlyUserCachesAndLogs() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let caches = root.appendingPathComponent("Library/Caches", isDirectory: true)
    let logs = root.appendingPathComponent("Library/Logs", isDirectory: true)
    let sensitive = root.appendingPathComponent("Library/Application Support/Game/Caches", isDirectory: true)
    try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: sensitive, withIntermediateDirectories: true)
    try Data("cache".utf8).write(to: caches.appendingPathComponent("user.cache"))
    try Data("log".utf8).write(to: logs.appendingPathComponent("user.log"))
    try Data("keep".utf8).write(to: sensitive.appendingPathComponent("sensitive.cache"))
    defer { try? FileManager.default.removeItem(at: root) }

    let privileged = RecordingPrivilegedOperator()
    let service = CacheService(privileged: privileged)
    let scan = await service.scan(excludingSensitiveFiles: true, homeURL: root)
    #expect(scan.userTargets.map(\.standardizedFileURL.path) == [caches, logs].map(\.standardizedFileURL.path))
    #expect(scan.systemTargets.isEmpty)
    try await service.clear(scan)

    #expect(!FileManager.default.fileExists(atPath: caches.appendingPathComponent("user.cache").path))
    #expect(!FileManager.default.fileExists(atPath: logs.appendingPathComponent("user.log").path))
    #expect(FileManager.default.fileExists(atPath: sensitive.appendingPathComponent("sensitive.cache").path))
    #expect(await privileged.operations.isEmpty)
}

@Test func cacheCleanupContinuesAfterAnInaccessibleEntry() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let blocked = root.appendingPathComponent("com.apple.HomeKit")
    let removable = root.appendingPathComponent("removable.cache")
    try FileManager.default.createDirectory(at: blocked, withIntermediateDirectories: true)
    try Data("remove".utf8).write(to: removable)
    defer { try? FileManager.default.removeItem(at: root) }

    let service = CacheService(privileged: RecordingPrivilegedOperator()) { url in
        if url.lastPathComponent == blocked.lastPathComponent {
            throw CocoaError(.fileWriteNoPermission)
        }
        try FileManager.default.removeItem(at: url)
    }
    try await service.clear(CacheScan(userTargets: [root], systemTargets: [], estimatedBytes: 6))

    #expect(FileManager.default.fileExists(atPath: blocked.path))
    #expect(!FileManager.default.fileExists(atPath: removable.path))
}

@Test func configurationNormalizesNewVersionThreePreferences() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = ConfigurationStore(configurationURL: root.appendingPathComponent("configuration.json"))
    var configuration = AppConfiguration()
    configuration.hoYoWaitSeconds = 99
    configuration.excludesSensitiveCacheFiles = false
    configuration.recentMetalHUDApps = [
        RecentMetalHUDApp(path: "/Applications/A.app", displayName: "A"),
        RecentMetalHUDApp(path: "/Applications/A.app", displayName: "Duplicate")
    ]
    try await store.save(configuration)
    let loaded = try await store.load(importLegacy: false)
    #expect(loaded.schemaVersion == 3)
    #expect(loaded.hoYoWaitSeconds == 15)
    #expect(!loaded.excludesSensitiveCacheFiles)
    #expect(loaded.recentMetalHUDApps == [RecentMetalHUDApp(path: "/Applications/A.app", displayName: "A")])
}

@Test func processRunnerDrainsOutputLargerThanPipeBuffer() async throws {
    let result = try await ProcessCommandRunner().run("/usr/bin/seq", arguments: ["1", "30000"])
    #expect(result.outputString.hasPrefix("1\n2\n3"))
    #expect(result.outputString.hasSuffix("30000"))
    #expect(result.standardOutput.count > 65_536)
}

actor MockRunner: CommandRunning {
    var calls: [[String]] = []
    var failingMount: String?
    var staleInfoReads: [String: Int]
    var reportedMountPaths: [String: String]

    init(failingMount: String? = nil, staleInfoReads: [String: Int] = [:], reportedMountPaths: [String: String] = [:]) {
        self.failingMount = failingMount
        self.staleInfoReads = staleInfoReads
        self.reportedMountPaths = reportedMountPaths
    }

    func run(_ executable: String, arguments: [String]) async throws -> CommandResult {
        calls.append(arguments)
        if arguments.contains("mount"), let failingMount, arguments.contains(where: { $0.contains(failingMount) }) {
            throw ToolboxError.commandFailed("fixture failure")
        }
        if arguments.first == "info" {
            let identifier = arguments.last ?? ""
            if let remaining = staleInfoReads[identifier], remaining > 0 {
                staleInfoReads[identifier] = remaining - 1
                let data = try PropertyListSerialization.data(fromPropertyList: ["MountPoint": "/Volumes/Stale"], format: .xml, options: 0)
                return CommandResult(exitCode: 0, standardOutput: data, standardError: Data())
            }
            let path = reportedMountPaths[identifier]
                ?? calls.last(where: { $0.contains("-mountPoint") && $0.last?.contains(identifier) == true })?.dropFirst(2).first
                ?? "/Volumes/Test"
            let data = try PropertyListSerialization.data(fromPropertyList: ["MountPoint": path], format: .xml, options: 0)
            return CommandResult(exitCode: 0, standardOutput: data, standardError: Data())
        }
        return CommandResult(exitCode: 0, standardOutput: Data(), standardError: Data())
    }
}

@Test func batchMountRollsBackEarlierVolumeOnFailure() async {
    let runner = MockRunner(failingMount: "disk5s1")
    let service = DiskService(runner: runner)
    _ = await service.mountBatch([("disk4s1", "/tmp/one"), ("disk5s1", "/tmp/two")])
    let calls = await runner.calls
    #expect(calls.contains(["mount", "disk4s1"]))
    #expect(calls.filter { $0 == ["unmount", "disk5s1"] }.count == 2)
}

@Test func mountWaitsForDiskutilInfoToReflectTheRequestedPath() async throws {
    let runner = MockRunner(staleInfoReads: ["disk4s1": 2])
    let service = DiskService(runner: runner)

    try await service.mount("disk4s1", at: "/tmp/delayed")

    let calls = await runner.calls
    #expect(calls.filter { $0 == ["info", "-plist", "disk4s1"] }.count == 3)
}

@Test func mountAcceptsEquivalentCanonicalMountPaths() async throws {
    let mountPath = "/tmp/mac-game-toolbox-canonical-\(UUID().uuidString)"
    try FileManager.default.createDirectory(atPath: mountPath, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(atPath: mountPath) }
    let runner = MockRunner(reportedMountPaths: ["disk4s1": "/private\(mountPath)"])
    let service = DiskService(runner: runner)

    try await service.mount("disk4s1", at: mountPath)
}

@Test func batchMountProcessesAllVolumesWithoutANumericalCap() async {
    let runner = MockRunner()
    let service = DiskService(runner: runner)
    let assignments = (1...1_000).map { ("disk\($0)s1", "/tmp/volume-\($0)") }

    let results = await service.mountBatch(assignments)

    #expect(results.count == assignments.count)
    #expect(results["disk4s1"] != nil)
    #expect(results["disk1000s1"] != nil)
}

@Test func gameSaveFinderScansAppDataAndSavedGames() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let bottlePath = root.appendingPathComponent("TestBottle")
    let appDataLocal = bottlePath.appendingPathComponent("drive_c/users/crossover/AppData/Local/EldenRing")
    let savedGames = bottlePath.appendingPathComponent("drive_c/users/crossover/Saved Games/Cyberpunk2077")
    try FileManager.default.createDirectory(at: appDataLocal, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: savedGames, withIntermediateDirectories: true)
    try "save data 1".write(to: appDataLocal.appendingPathComponent("save.dat"), atomically: true, encoding: .utf8)
    try "save data 2".write(to: savedGames.appendingPathComponent("manualsave_0.sav"), atomically: true, encoding: .utf8)

    defer { try? FileManager.default.removeItem(at: root) }

    let finder = GameSaveFinderService()
    let bottle = WineBottle(name: "TestBottle", type: .crossover, path: bottlePath.path)
    let saves = await finder.scanSaveDirectories(in: bottle)

    #expect(saves.count == 2)
    let gameNames = Set(saves.map(\.gameName))
    #expect(gameNames.contains("EldenRing"))
    #expect(gameNames.contains("Cyberpunk2077"))
}

@Test func perAppProfilesRoundTripThroughConfiguration() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = ConfigurationStore(configurationURL: root.appendingPathComponent("configuration.json"))
    var config = AppConfiguration()
    let customOpts = MetalHUDOptions(scale: 0.8, alignment: "bottomleft", elements: ["fps", "gputime"])
    config.perAppHUDProfiles = [
        PerAppMetalHUDProfile(appPath: "/Applications/Cyberpunk.app", appName: "Cyberpunk", options: customOpts)
    ]
    try await store.save(config)

    let loaded = try await store.load(homeURL: root)
    #expect(loaded.perAppHUDProfiles.count == 1)
    #expect(loaded.perAppHUDProfiles.first?.appPath == "/Applications/Cyberpunk.app")
    #expect(loaded.perAppHUDProfiles.first?.options.scale == 0.8)
    #expect(loaded.perAppHUDProfiles.first?.options.alignment == "bottomleft")
}

@Test func performanceSnapshotGeneratesValidMarkdown() async throws {
    let snapshotService = PerformanceSnapshotService()
    let opts = MetalHUDOptions(scale: 0.5, alignment: "topright", elements: ["fps", "memory"])
    let report = await snapshotService.generateSnapshotReport(metalHUDOptions: opts, activeApp: "MiSide.app")

    #expect(report.contains("# Mac 游戏工具箱 - 性能诊断快照报告"))
    #expect(report.contains("MiSide.app"))
    #expect(report.contains("MTL_HUD_ENABLED=1"))
    #expect(report.contains("0.50"))
    #expect(report.contains("Apple Silicon"))
}

@Test func wineBottleTypesHaveAppropriateIcons() {
    #expect(WineBottleType.crossover.iconName == "shippingbox.fill")
    #expect(WineBottleType.whisky.iconName == "wineglass.fill")
    #expect(WineBottleType.heroic.iconName == "gamecontroller.fill")
    #expect(WineBottleType.customWine.iconName == "folder.fill.badge.gearshape")
}

@Test func systemHealthInspectorGathersDiagnosticItems() async throws {
    let inspector = SystemHealthInspector()
    let report = await inspector.performFullHealthCheck(privileged: nil)

    #expect(!report.items.isEmpty)
    let names = report.items.map(\.nameZh)
    #expect(names.contains("特权辅助服务 (Privileged Helper)"))
    #expect(names.contains("Metal HUD 注入环境"))
    #expect(names.contains("缓存与本地存储访问权限"))
}

@Test func healthReportModelsRoundTrip() throws {
    let item = HealthCheckItem(nameZh: "测试服务", nameEn: "Test Service", nameJa: "テストサービス", status: .healthy, detailZh: "一切正常", detailEn: "All good", detailJa: "すべて正常")
    let report = SystemHealthReport(items: [item], legacyHelpersFound: [], checkedAt: Date())
    let data = try JSONEncoder().encode(report)
    let decoded = try JSONDecoder().decode(SystemHealthReport.self, from: data)

    #expect(decoded.allHealthy)
    #expect(decoded.items.count == 1)
    #expect(decoded.items.first?.nameZh == "测试服务")
    #expect(decoded.items.first?.nameJa == "テストサービス")
    #expect(decoded.items.first?.detailJa == "すべて正常")
}

@Test func languagePreferenceEnumAndConfigurationRoundTrip() async throws {
    #expect(AppLanguagePreference.allCases.count == 4)
    #expect(AppLanguagePreference.system.rawValue == "system")
    #expect(AppLanguagePreference.chinese.rawValue == "zh-Hans")
    #expect(AppLanguagePreference.english.rawValue == "en")
    #expect(AppLanguagePreference.japanese.rawValue == "ja")

    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = ConfigurationStore(configurationURL: root.appendingPathComponent("configuration.json"))
    var config = AppConfiguration()
    config.languagePreference = .japanese
    try await store.save(config)

    let loaded = try await store.load(homeURL: root)
    #expect(loaded.languagePreference == .japanese)
}

@Test func navigationCategoryProvidesJapaneseTitles() {
    #expect(NavigationCategory.overview.titleJa == "概要とステータス")
    #expect(NavigationCategory.frameGen.titleJa == "超解像と補フレーム")
    #expect(NavigationCategory.metalHUD.titleJa == "Metal HUD 設定")
    #expect(NavigationCategory.gameBoost.titleJa == "ゲーム高速化・起動")
    #expect(NavigationCategory.storage.titleJa == "ストレージとセーブ")
    #expect(NavigationCategory.system.titleJa == "システムと設定")
    #expect(NavigationCategory.about.titleJa == "情報と謝辞")
}

@Test func scalingModelsAndSettingsRoundTrip() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = ConfigurationStore(configurationURL: root.appendingPathComponent("configuration.json"))
    var config = AppConfiguration()
    config.scalingSettings = ScalingSettings(
        enabled: true,
        frameGenMode: .extrapolation3x,
        renderScale: .scale67,
        qualityProfile: .ultra,
        aaMode: .smaa,
        casEnabled: true,
        sharpness: 0.75,
        sceneCutDetectionEnabled: true,
        dynamicResolutionScaling: true,
        syntheticCursorEnabled: true,
        hudEnabled: true,
        targetWindowBundleID: "com.example.game",
        targetWindowName: "Demo Game"
    )
    try await store.save(config)

    let loaded = try await store.load(homeURL: root)
    #expect(loaded.scalingSettings.frameGenMode == .extrapolation3x)
    #expect(loaded.scalingSettings.frameGenMode.isExtrapolation)
    #expect(loaded.scalingSettings.frameGenMode.multiplier == 3)
    #expect(loaded.scalingSettings.renderScale == .scale67)
    #expect(loaded.scalingSettings.aaMode == .smaa)
    #expect(ScalingAAMode.allCases.contains(.taa))
    #expect(ScalingAAMode.taa.titleEn == "TAA (Temporal)")
    #expect(loaded.scalingSettings.sharpness == 0.75)
    #expect(loaded.scalingSettings.targetWindowName == "Demo Game")
}



