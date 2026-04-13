import Foundation
import os.log

private let logger = Logger(subsystem: "com.zerohachiko.notchi-remix", category: "HookInstaller")

struct HookInstaller {

    // MARK: - Claude Code Hooks

    @discardableResult
    static func installIfNeeded() -> Bool {
        let claudeDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")

        guard FileManager.default.fileExists(atPath: claudeDir.path) else {
            logger.warning("Claude Code not installed (~/.claude not found)")
            return false
        }

        let hooksDir = claudeDir.appendingPathComponent("hooks")
        let hookScript = hooksDir.appendingPathComponent("notchi-hook.sh")
        let settings = claudeDir.appendingPathComponent("settings.json")

        do {
            try FileManager.default.createDirectory(
                at: hooksDir,
                withIntermediateDirectories: true
            )
        } catch {
            logger.error("Failed to create hooks directory: \(error.localizedDescription)")
            return false
        }

        if let bundled = Bundle.main.url(forResource: "notchi-hook", withExtension: "sh") {
            do {
                let bundledData = try Data(contentsOf: bundled)
                try bundledData.write(to: hookScript, options: .atomic)
                try FileManager.default.setAttributes(
                    [.posixPermissions: 0o755],
                    ofItemAtPath: hookScript.path
                )
                logger.info("Installed hook script to \(hookScript.path, privacy: .public)")
            } catch {
                logger.error("Failed to install hook script: \(error.localizedDescription)")
                return false
            }
        } else {
            logger.error("Hook script not found in bundle")
            return false
        }

        return updateSettings(at: settings)
    }

    private static func updateSettings(at settingsURL: URL) -> Bool {
        var json: [String: Any] = [:]
        if let data = try? Data(contentsOf: settingsURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = existing
        }

        let command = "~/.claude/hooks/notchi-hook.sh"
        let hookEntry: [[String: Any]] = [["type": "command", "command": command]]
        let withMatcher: [[String: Any]] = [["matcher": "*", "hooks": hookEntry]]
        let withoutMatcher: [[String: Any]] = [["hooks": hookEntry]]
        let preCompactConfig: [[String: Any]] = [
            ["matcher": "auto", "hooks": hookEntry],
            ["matcher": "manual", "hooks": hookEntry]
        ]

        var hooks = json["hooks"] as? [String: Any] ?? [:]

        let hookEvents: [(String, [[String: Any]])] = [
            ("UserPromptSubmit", withoutMatcher),
            ("SessionStart", withoutMatcher),
            ("PreToolUse", withMatcher),
            ("PostToolUse", withMatcher),
            ("PermissionRequest", withMatcher),
            ("PreCompact", preCompactConfig),
            ("Stop", withoutMatcher),
            ("SubagentStop", withoutMatcher),
            ("SessionEnd", withoutMatcher),
        ]

        for (event, config) in hookEvents {
            if var existingEvent = hooks[event] as? [[String: Any]] {
                let hasOurHook = existingEvent.contains { entry in
                    if let entryHooks = entry["hooks"] as? [[String: Any]] {
                        return entryHooks.contains { h in
                            let cmd = h["command"] as? String ?? ""
                            return cmd.contains("notchi-hook.sh")
                        }
                    }
                    return false
                }
                if !hasOurHook {
                    existingEvent.append(contentsOf: config)
                    hooks[event] = existingEvent
                }
            } else {
                hooks[event] = config
            }
        }

        json["hooks"] = hooks

        guard let data = try? JSONSerialization.data(
            withJSONObject: json,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            logger.error("Failed to serialize settings JSON")
            return false
        }

        do {
            try data.write(to: settingsURL)
            logger.info("Updated settings.json with Notchi Remix hooks")
            return true
        } catch {
            logger.error("Failed to write settings.json: \(error.localizedDescription)")
            return false
        }
    }

    static func isInstalled() -> Bool {
        let settings = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")

        guard let data = try? Data(contentsOf: settings),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = json["hooks"] as? [String: Any] else {
            return false
        }

        return hooks.values.contains { value in
            guard let entries = value as? [[String: Any]] else { return false }
            return entries.contains { entry in
                guard let entryHooks = entry["hooks"] as? [[String: Any]] else { return false }
                return entryHooks.contains { hook in
                    (hook["command"] as? String)?.contains("notchi-hook.sh") == true
                }
            }
        }
    }

    static func uninstall() {
        let claudeDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
        let hooksDir = claudeDir.appendingPathComponent("hooks")
        let hookScript = hooksDir.appendingPathComponent("notchi-hook.sh")
        let settings = claudeDir.appendingPathComponent("settings.json")

        try? FileManager.default.removeItem(at: hookScript)

        guard let data = try? Data(contentsOf: settings),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var hooks = json["hooks"] as? [String: Any] else {
            return
        }

        for (event, value) in hooks {
            if var entries = value as? [[String: Any]] {
                entries.removeAll { entry in
                    if let entryHooks = entry["hooks"] as? [[String: Any]] {
                        return entryHooks.contains { hook in
                            let cmd = hook["command"] as? String ?? ""
                            return cmd.contains("notchi-hook.sh")
                        }
                    }
                    return false
                }

                if entries.isEmpty {
                    hooks.removeValue(forKey: event)
                } else {
                    hooks[event] = entries
                }
            }
        }

        if hooks.isEmpty {
            json.removeValue(forKey: "hooks")
        } else {
            json["hooks"] = hooks
        }

        if let data = try? JSONSerialization.data(
            withJSONObject: json,
            options: [.prettyPrinted, .sortedKeys]
        ) {
            try? data.write(to: settings)
        }

        logger.info("Uninstalled Notchi Remix hooks")
    }

    // MARK: - Codex Hooks

    @discardableResult
    static func installCodexIfNeeded() -> Bool {
        let codexDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex")

        guard FileManager.default.fileExists(atPath: codexDir.path) else {
            logger.info("Codex CLI not installed (~/.codex not found), skipping")
            return false
        }

        let hookScript = codexDir.appendingPathComponent("notchi-codex-hook.sh")

        if let bundled = Bundle.main.url(forResource: "notchi-codex-hook", withExtension: "sh") {
            do {
                let bundledData = try Data(contentsOf: bundled)
                try bundledData.write(to: hookScript, options: .atomic)
                try FileManager.default.setAttributes(
                    [.posixPermissions: 0o755],
                    ofItemAtPath: hookScript.path
                )
                logger.info("Installed Codex hook script to \(hookScript.path, privacy: .public)")
            } catch {
                logger.error("Failed to install Codex hook script: \(error.localizedDescription)")
                return false
            }
        } else {
            logger.error("Codex hook script not found in bundle")
            return false
        }

        let hooksJsonOK = updateCodexHooksJson(in: codexDir, hookScriptPath: hookScript.path)
        let configOK = enableCodexHooksFeatureFlag(in: codexDir)

        return hooksJsonOK && configOK
    }

    private static func updateCodexHooksJson(in codexDir: URL, hookScriptPath: String) -> Bool {
        let hooksJsonURL = codexDir.appendingPathComponent("hooks.json")

        var root: [String: Any] = [:]
        if let data = try? Data(contentsOf: hooksJsonURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            root = existing
        }

        var hooks = root["hooks"] as? [String: Any] ?? [:]

        let command = hookScriptPath
        let hookHandler: [String: Any] = ["type": "command", "command": command]

        let codexEvents: [(String, [String: Any]?)] = [
            ("SessionStart", ["matcher": "startup|resume"]),
            ("UserPromptSubmit", nil),
            ("PreToolUse", ["matcher": "Bash"]),
            ("PostToolUse", ["matcher": "Bash"]),
            ("Stop", nil),
        ]

        for (event, matcherConfig) in codexEvents {
            var group: [String: Any] = ["hooks": [hookHandler]]
            if let mc = matcherConfig {
                for (k, v) in mc { group[k] = v }
            }

            if var existingEvent = hooks[event] as? [[String: Any]] {
                let hasOurHook = existingEvent.contains { entry in
                    if let entryHooks = entry["hooks"] as? [[String: Any]] {
                        return entryHooks.contains { h in
                            let cmd = h["command"] as? String ?? ""
                            return cmd.contains("notchi-codex-hook.sh")
                        }
                    }
                    return false
                }
                if !hasOurHook {
                    existingEvent.append(group)
                    hooks[event] = existingEvent
                }
            } else {
                hooks[event] = [group]
            }
        }

        root["hooks"] = hooks

        guard let data = try? JSONSerialization.data(
            withJSONObject: root,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            logger.error("Failed to serialize Codex hooks.json")
            return false
        }

        do {
            try data.write(to: hooksJsonURL)
            logger.info("Updated ~/.codex/hooks.json with Notchi Remix hooks")
            return true
        } catch {
            logger.error("Failed to write hooks.json: \(error.localizedDescription)")
            return false
        }
    }

    private static func enableCodexHooksFeatureFlag(in codexDir: URL) -> Bool {
        let configURL = codexDir.appendingPathComponent("config.toml")

        var contents = ""
        if let data = try? Data(contentsOf: configURL),
           let existing = String(data: data, encoding: .utf8) {
            contents = existing
        }

        if contents.contains("codex_hooks") {
            if contents.contains("codex_hooks = true") {
                logger.info("Codex hooks feature flag already enabled")
                return true
            }
            contents = contents.replacingOccurrences(
                of: "codex_hooks = false",
                with: "codex_hooks = true"
            )
        } else {
            if contents.contains("[features]") {
                contents = contents.replacingOccurrences(
                    of: "[features]",
                    with: "[features]\ncodex_hooks = true"
                )
            } else {
                if !contents.isEmpty && !contents.hasSuffix("\n") {
                    contents += "\n"
                }
                contents += "\n[features]\ncodex_hooks = true\n"
            }
        }

        do {
            try contents.write(to: configURL, atomically: true, encoding: .utf8)
            logger.info("Enabled codex_hooks feature flag in config.toml")
            return true
        } catch {
            logger.error("Failed to write config.toml: \(error.localizedDescription)")
            return false
        }
    }

    static func isCodexInstalled() -> Bool {
        let codexDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex")
        let hooksJsonURL = codexDir.appendingPathComponent("hooks.json")

        guard let data = try? Data(contentsOf: hooksJsonURL),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = root["hooks"] as? [String: Any] else {
            return false
        }

        return hooks.values.contains { value in
            guard let entries = value as? [[String: Any]] else { return false }
            return entries.contains { entry in
                guard let entryHooks = entry["hooks"] as? [[String: Any]] else { return false }
                return entryHooks.contains { hook in
                    (hook["command"] as? String)?.contains("notchi-codex-hook.sh") == true
                }
            }
        }
    }

    static func codexAvailable() -> Bool {
        let codexDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex")
        return FileManager.default.fileExists(atPath: codexDir.path)
    }

    static func uninstallCodex() {
        let codexDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex")
        let hookScript = codexDir.appendingPathComponent("notchi-codex-hook.sh")
        let hooksJsonURL = codexDir.appendingPathComponent("hooks.json")

        try? FileManager.default.removeItem(at: hookScript)

        guard let data = try? Data(contentsOf: hooksJsonURL),
              var root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var hooks = root["hooks"] as? [String: Any] else {
            return
        }

        for (event, value) in hooks {
            if var entries = value as? [[String: Any]] {
                entries.removeAll { entry in
                    if let entryHooks = entry["hooks"] as? [[String: Any]] {
                        return entryHooks.contains { hook in
                            let cmd = hook["command"] as? String ?? ""
                            return cmd.contains("notchi-codex-hook.sh")
                        }
                    }
                    return false
                }

                if entries.isEmpty {
                    hooks.removeValue(forKey: event)
                } else {
                    hooks[event] = entries
                }
            }
        }

        if hooks.isEmpty {
            root.removeValue(forKey: "hooks")
        } else {
            root["hooks"] = hooks
        }

        if let data = try? JSONSerialization.data(
            withJSONObject: root,
            options: [.prettyPrinted, .sortedKeys]
        ) {
            try? data.write(to: hooksJsonURL)
        }

        logger.info("Uninstalled Notchi Remix Codex hooks")
    }
}
