import Foundation
import os

private let logger = Logger(subsystem: "com.zerohachiko.notchi-remix", category: "ClaudeSettingsStore")

enum SaveStatus: Equatable {
    case idle
    case saved
    case error(String)
}

@MainActor
@Observable
final class ClaudeSettingsStore {
    static let shared = ClaudeSettingsStore()
    static let settingsPath = NSString("~/.claude/settings.json").expandingTildeInPath

    private(set) var settings = ClaudeSettings()
    private(set) var saveStatus: SaveStatus = .idle
    private var rawJSON: [String: Any] = [:]
    private var resetTask: Task<Void, Never>?

    private init() {}

    func load() {
        let path = Self.settingsPath
        guard FileManager.default.fileExists(atPath: path),
              let data = FileManager.default.contents(atPath: path) else {
            logger.info("No settings file found at \(path, privacy: .public)")
            settings = ClaudeSettings()
            rawJSON = [:]
            return
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                rawJSON = json
            }
            let decoder = JSONDecoder()
            decoder.userInfo[.rawJSONData] = data
            settings = try decoder.decode(ClaudeSettings.self, from: data)
            logger.info("Loaded settings from \(path, privacy: .public)")
        } catch {
            logger.error("Failed to decode settings: \(error.localizedDescription, privacy: .public)")
            settings = ClaudeSettings()
            rawJSON = [:]
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let encodedData = try encoder.encode(settings)

            guard let encodedDict = try JSONSerialization.jsonObject(with: encodedData) as? [String: Any] else {
                throw NSError(domain: "ClaudeSettingsStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize encoded settings"])
            }

            var merged = rawJSON
            for (key, value) in encodedDict {
                merged[key] = value
            }

            let outputData = try JSONSerialization.data(withJSONObject: merged, options: [.prettyPrinted, .sortedKeys])

            let url = URL(fileURLWithPath: Self.settingsPath)
            let directory = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try outputData.write(to: url, options: .atomic)

            rawJSON = merged
            saveStatus = .saved
            logger.info("Settings saved to \(Self.settingsPath, privacy: .public)")

            resetTask?.cancel()
            resetTask = Task {
                try? await Task.sleep(for: .seconds(1.5))
                guard !Task.isCancelled else { return }
                saveStatus = .idle
            }
        } catch {
            saveStatus = .error(error.localizedDescription)
            logger.error("Failed to save settings: \(error.localizedDescription, privacy: .public)")
        }
    }

    func updateEnvVar(key: String, value: String) {
        if settings.env == nil { settings.env = [:] }
        settings.env?[key] = value
        save()
    }

    func addEnvVar(key: String, value: String) {
        if settings.env == nil { settings.env = [:] }
        settings.env?[key] = value
        save()
    }

    func removeEnvVar(key: String) {
        settings.env?.removeValue(forKey: key)
        if settings.env?.isEmpty == true { settings.env = nil }
        save()
    }

    func setPlugin(_ name: String, enabled: Bool) {
        if settings.enabledPlugins == nil { settings.enabledPlugins = [:] }
        settings.enabledPlugins?[name] = enabled
        save()
    }

    func removePlugin(_ name: String) {
        settings.enabledPlugins?.removeValue(forKey: name)
        if settings.enabledPlugins?.isEmpty == true { settings.enabledPlugins = nil }
        save()
    }

    func addHookEntry(eventType: String, entry: HookEntry, matcher: String? = nil) {
        if settings.hooks == nil { settings.hooks = [:] }
        if settings.hooks?[eventType] == nil { settings.hooks?[eventType] = [] }

        let effectiveMatcher = matcher ?? "*"
        if let index = settings.hooks?[eventType]?.firstIndex(where: { $0.matcher == effectiveMatcher }) {
            settings.hooks?[eventType]?[index].hooks.append(entry)
        } else {
            let config = HookEventConfig(matcher: effectiveMatcher, hooks: [entry])
            settings.hooks?[eventType]?.append(config)
        }
        save()
    }

    func removeHookEntry(eventType: String, configIndex: Int, hookIndex: Int) {
        guard var configs = settings.hooks?[eventType],
              configIndex < configs.count,
              hookIndex < configs[configIndex].hooks.count else { return }

        configs[configIndex].hooks.remove(at: hookIndex)
        if configs[configIndex].hooks.isEmpty {
            configs.remove(at: configIndex)
        }
        settings.hooks?[eventType] = configs.isEmpty ? nil : configs
        if settings.hooks?.values.allSatisfy({ $0 == nil }) == true || settings.hooks?.isEmpty == true {
            settings.hooks = nil
        }
        save()
    }

    func addPermission(type: String, value: String) {
        if settings.permissions == nil { settings.permissions = PermissionsConfig() }
        switch type {
        case "allow":
            if !settings.permissions!.allow.contains(value) {
                settings.permissions?.allow.append(value)
            }
        case "deny":
            if !settings.permissions!.deny.contains(value) {
                settings.permissions?.deny.append(value)
            }
        default:
            break
        }
        save()
    }

    func removePermission(type: String, index: Int) {
        switch type {
        case "allow":
            guard let perms = settings.permissions, index < perms.allow.count else { return }
            settings.permissions?.allow.remove(at: index)
        case "deny":
            guard let perms = settings.permissions, index < perms.deny.count else { return }
            settings.permissions?.deny.remove(at: index)
        default:
            return
        }
        if settings.permissions?.allow.isEmpty == true && settings.permissions?.deny.isEmpty == true {
            settings.permissions = nil
        }
        save()
    }

    func updateStatusLine(command: String) {
        settings.statusLine = StatusLineConfig(command: command)
        save()
    }

    func updateBasicSetting(_ keyPath: WritableKeyPath<ClaudeSettings, Bool?>, value: Bool) {
        settings[keyPath: keyPath] = value
        save()
    }

    func addMarketplace(name: String, repo: String, source: String) {
        if settings.extraKnownMarketplaces == nil { settings.extraKnownMarketplaces = [:] }
        settings.extraKnownMarketplaces?[name] = MarketplaceConfig(source: MarketplaceSource(repo: repo, source: source))
        save()
    }

    func removeMarketplace(name: String) {
        settings.extraKnownMarketplaces?.removeValue(forKey: name)
        if settings.extraKnownMarketplaces?.isEmpty == true { settings.extraKnownMarketplaces = nil }
        save()
    }
}
