import Foundation
import os

private let logger = Logger(subsystem: "com.zerohachiko.notchi-remix", category: "CodexSettingsStore")

@MainActor
@Observable
final class CodexSettingsStore {
    static let shared = CodexSettingsStore()
    static let configPath = NSString("~/.codex/config.toml").expandingTildeInPath
    static let hooksPath = NSString("~/.codex/hooks.json").expandingTildeInPath

    private(set) var settings = CodexSettings()
    private(set) var saveStatus: SaveStatus = .idle
    private(set) var isDirty = false
    private var rawToml = ""
    private var savedRawToml = ""
    private var rawHooksJSON: [String: Any] = [:]
    private var savedRawHooksJSON: [String: Any] = [:]
    private var savedSettings = CodexSettings()
    private var resetTask: Task<Void, Never>?

    var isAvailable: Bool {
        FileManager.default.fileExists(atPath: NSString("~/.codex").expandingTildeInPath)
    }

    private init() {}

    // MARK: - Load

    func load() {
        settings = CodexSettings()
        loadConfig()
        loadHooks()
        snapshotSavedState()
        isDirty = false
    }

    private func snapshotSavedState() {
        savedRawToml = rawToml
        savedRawHooksJSON = rawHooksJSON
        savedSettings = settings
    }

    private func loadConfig() {
        let path = Self.configPath
        guard FileManager.default.fileExists(atPath: path),
              let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            logger.info("No config.toml found at \(path, privacy: .public)")
            rawToml = ""
            return
        }

        rawToml = content
        parseConfigToml(content)
        logger.info("Loaded config.toml from \(path, privacy: .public)")
    }

    private func parseConfigToml(_ text: String) {
        var currentSection: String? = nil

        for line in text.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            // Section header
            if trimmed.hasPrefix("[") && !trimmed.hasPrefix("[[") {
                if let closing = trimmed.firstIndex(of: "]") {
                    currentSection = String(trimmed[trimmed.index(after: trimmed.startIndex)..<closing])
                        .trimmingCharacters(in: .whitespaces)
                }
                continue
            }

            // Key = value
            guard let eqIndex = trimmed.firstIndex(of: "=") else { continue }
            let key = String(trimmed[trimmed.startIndex..<eqIndex]).trimmingCharacters(in: .whitespaces)
            let rawValue = stripInlineComment(
                String(trimmed[trimmed.index(after: eqIndex)...]).trimmingCharacters(in: .whitespaces)
            )

            switch currentSection {
            case nil:
                parseTopLevelKey(key, value: rawValue)
            case "features":
                if let boolVal = parseBool(rawValue) {
                    settings.features[key] = boolVal
                }
            case "tools":
                if let boolVal = parseBool(rawValue) {
                    settings.tools[key] = boolVal
                }
            case "history":
                if key == "persistence" {
                    settings.historyPersistence = unquote(rawValue)
                }
            default:
                break
            }
        }
    }

    private func parseTopLevelKey(_ key: String, value: String) {
        switch key {
        case "model":
            settings.model = unquote(value)
        case "model_provider":
            settings.modelProvider = unquote(value)
        case "approval_policy":
            settings.approvalPolicy = unquote(value)
        case "sandbox_mode":
            settings.sandboxMode = unquote(value)
        case "model_reasoning_effort":
            settings.modelReasoningEffort = unquote(value)
        case "model_reasoning_summary":
            settings.modelReasoningSummary = unquote(value)
        case "file_opener":
            settings.fileOpener = unquote(value)
        case "hide_agent_reasoning":
            settings.hideAgentReasoning = parseBool(value)
        case "disable_response_storage":
            settings.disableResponseStorage = parseBool(value)
        case "model_verbosity":
            settings.modelVerbosity = unquote(value)
        default:
            break
        }
    }

    private func loadHooks() {
        let path = Self.hooksPath
        guard FileManager.default.fileExists(atPath: path),
              let data = FileManager.default.contents(atPath: path) else {
            logger.info("No hooks.json found at \(path, privacy: .public)")
            settings.hooks = nil
            rawHooksJSON = [:]
            return
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                rawHooksJSON = json
            }

            guard let hooksDict = rawHooksJSON["hooks"] as? [String: Any] else {
                settings.hooks = nil
                return
            }

            var parsed: [String: [CodexHookEventConfig]] = [:]
            for (eventType, value) in hooksDict {
                guard let entries = value as? [[String: Any]] else { continue }
                var configs: [CodexHookEventConfig] = []
                for entry in entries {
                    let matcher = entry["matcher"] as? String
                    var hookEntries: [CodexHookEntry] = []
                    if let hooks = entry["hooks"] as? [[String: Any]] {
                        for h in hooks {
                            let cmd = h["command"] as? String ?? ""
                            let type = h["type"] as? String ?? "command"
                            hookEntries.append(CodexHookEntry(command: cmd, type: type))
                        }
                    }
                    configs.append(CodexHookEventConfig(matcher: matcher, hooks: hookEntries))
                }
                parsed[eventType] = configs
            }
            settings.hooks = parsed.isEmpty ? nil : parsed
            logger.info("Loaded hooks.json from \(path, privacy: .public)")
        } catch {
            logger.error("Failed to decode hooks.json: \(error.localizedDescription, privacy: .public)")
            settings.hooks = nil
            rawHooksJSON = [:]
        }
    }

    // MARK: - Save

    private func saveConfig() {
        do {
            let url = URL(fileURLWithPath: Self.configPath)
            let directory = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try rawToml.write(to: url, atomically: true, encoding: .utf8)

            saveStatus = .saved
            logger.info("Config saved to \(Self.configPath, privacy: .public)")
            scheduleStatusReset()
        } catch {
            saveStatus = .error(error.localizedDescription)
            logger.error("Failed to save config.toml: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func saveHooks() {
        guard settings.hooks != nil else { return }

        do {
            var hooksDict: [String: Any] = [:]
            for (eventType, configs) in settings.hooks ?? [:] {
                var entries: [[String: Any]] = []
                for config in configs {
                    var entry: [String: Any] = [:]
                    if let matcher = config.matcher {
                        entry["matcher"] = matcher
                    }
                    var hooks: [[String: Any]] = []
                    for h in config.hooks {
                        hooks.append(["type": h.type, "command": h.command])
                    }
                    entry["hooks"] = hooks
                    entries.append(entry)
                }
                hooksDict[eventType] = entries
            }

            var root = rawHooksJSON
            root["hooks"] = hooksDict

            let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
            let url = URL(fileURLWithPath: Self.hooksPath)
            try data.write(to: url, options: .atomic)

            rawHooksJSON = root
            saveStatus = .saved
            logger.info("Hooks saved to \(Self.hooksPath, privacy: .public)")
            scheduleStatusReset()
        } catch {
            saveStatus = .error(error.localizedDescription)
            logger.error("Failed to save hooks.json: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func scheduleStatusReset() {
        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            saveStatus = .idle
        }
    }

    // MARK: - Commit / Discard

    func commitSave() {
        saveConfig()
        saveHooks()
        snapshotSavedState()
        isDirty = false
    }

    func discardChanges() {
        rawToml = savedRawToml
        rawHooksJSON = savedRawHooksJSON
        settings = savedSettings
        isDirty = false
        saveStatus = .idle
    }

    // MARK: - Update methods

    func updateTopLevel(_ key: String, value: String?) {
        if let value = value {
            let needsQuotes = !["true", "false"].contains(value.lowercased()) && Int(value) == nil
            let tomlValue = needsQuotes ? "\"\(value)\"" : value
            rawToml = replaceOrInsertTomlKey(in: rawToml, section: nil, key: key, value: tomlValue)
        } else {
            rawToml = removeTomlKey(in: rawToml, section: nil, key: key)
        }
        settings = CodexSettings()
        parseConfigToml(rawToml)
        loadHooks()
        isDirty = true
    }

    func updateTopLevelBool(_ key: String, value: Bool) {
        rawToml = replaceOrInsertTomlKey(in: rawToml, section: nil, key: key, value: value ? "true" : "false")
        let hooks = settings.hooks
        settings = CodexSettings()
        parseConfigToml(rawToml)
        settings.hooks = hooks
        isDirty = true
    }

    func updateFeature(_ key: String, value: Bool) {
        rawToml = replaceOrInsertTomlKey(in: rawToml, section: "features", key: key, value: value ? "true" : "false")
        let hooks = settings.hooks
        settings = CodexSettings()
        parseConfigToml(rawToml)
        settings.hooks = hooks
        isDirty = true
    }

    func updateTool(_ key: String, value: Bool) {
        rawToml = replaceOrInsertTomlKey(in: rawToml, section: "tools", key: key, value: value ? "true" : "false")
        let hooks = settings.hooks
        settings = CodexSettings()
        parseConfigToml(rawToml)
        settings.hooks = hooks
        isDirty = true
    }

    func addHookEntry(eventType: String, entry: CodexHookEntry, matcher: String? = nil) {
        if settings.hooks == nil { settings.hooks = [:] }
        if settings.hooks?[eventType] == nil { settings.hooks?[eventType] = [] }

        if let index = settings.hooks?[eventType]?.firstIndex(where: { $0.matcher == matcher }) {
            settings.hooks?[eventType]?[index].hooks.append(entry)
        } else {
            let config = CodexHookEventConfig(matcher: matcher, hooks: [entry])
            settings.hooks?[eventType]?.append(config)
        }
        isDirty = true
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
        isDirty = true
    }

    // MARK: - TOML helpers

    private func unquote(_ value: String) -> String {
        let v = value.trimmingCharacters(in: .whitespaces)
        if (v.hasPrefix("\"") && v.hasSuffix("\"")) || (v.hasPrefix("'") && v.hasSuffix("'")) {
            return String(v.dropFirst().dropLast())
        }
        return v
    }

    private func parseBool(_ value: String) -> Bool? {
        let v = value.trimmingCharacters(in: .whitespaces).lowercased()
        if v == "true" { return true }
        if v == "false" { return false }
        return nil
    }

    private func stripInlineComment(_ value: String) -> String {
        var inQuote = false
        var quoteChar: Character = "\""
        for (i, c) in value.enumerated() {
            if !inQuote && (c == "\"" || c == "'") {
                inQuote = true
                quoteChar = c
            } else if inQuote && c == quoteChar {
                inQuote = false
            } else if !inQuote && c == "#" {
                return String(value.prefix(i)).trimmingCharacters(in: .whitespaces)
            }
        }
        return value
    }

    private func replaceOrInsertTomlKey(in toml: String, section: String?, key: String, value: String) -> String {
        var lines = toml.components(separatedBy: "\n")
        var currentSection: String? = nil
        var keyLineIndex: Int? = nil
        var sectionHeaderIndex: Int? = nil
        var lastLineInSection: Int? = nil
        var firstSectionHeaderIndex: Int? = nil

        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("[") && !trimmed.hasPrefix("[[") {
                if let closing = trimmed.firstIndex(of: "]") {
                    let sec = String(trimmed[trimmed.index(after: trimmed.startIndex)..<closing])
                        .trimmingCharacters(in: .whitespaces)
                    if firstSectionHeaderIndex == nil {
                        firstSectionHeaderIndex = i
                    }
                    currentSection = sec
                    if sec == section {
                        sectionHeaderIndex = i
                    }
                }
                continue
            }

            if currentSection == section && !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                lastLineInSection = i

                if trimmed.contains("=") {
                    let eqIdx = trimmed.firstIndex(of: "=")!
                    let lineKey = String(trimmed[trimmed.startIndex..<eqIdx]).trimmingCharacters(in: .whitespaces)
                    if lineKey == key {
                        keyLineIndex = i
                    }
                }
            }
        }

        if let idx = keyLineIndex {
            lines[idx] = "\(key) = \(value)"
        } else if section == nil {
            if let lastLine = lastLineInSection {
                lines.insert("\(key) = \(value)", at: lastLine + 1)
            } else {
                let insertAt = firstSectionHeaderIndex ?? lines.count
                lines.insert("\(key) = \(value)", at: insertAt)
            }
        } else if sectionHeaderIndex != nil {
            let insertAt = (lastLineInSection ?? sectionHeaderIndex!) + 1
            lines.insert("\(key) = \(value)", at: insertAt)
        } else {
            if !lines.isEmpty && !(lines.last?.isEmpty ?? true) {
                lines.append("")
            }
            lines.append("[\(section!)]")
            lines.append("\(key) = \(value)")
        }

        return lines.joined(separator: "\n")
    }

    private func removeTomlKey(in toml: String, section: String?, key: String) -> String {
        var lines = toml.components(separatedBy: "\n")
        var currentSection: String? = nil

        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("[") && !trimmed.hasPrefix("[[") {
                if let closing = trimmed.firstIndex(of: "]") {
                    currentSection = String(trimmed[trimmed.index(after: trimmed.startIndex)..<closing])
                        .trimmingCharacters(in: .whitespaces)
                }
                continue
            }

            if currentSection == section && !trimmed.hasPrefix("#") && trimmed.contains("=") {
                let eqIdx = trimmed.firstIndex(of: "=")!
                let lineKey = String(trimmed[trimmed.startIndex..<eqIdx]).trimmingCharacters(in: .whitespaces)
                if lineKey == key {
                    lines.remove(at: i)
                    return lines.joined(separator: "\n")
                }
            }
        }

        return toml
    }
}
