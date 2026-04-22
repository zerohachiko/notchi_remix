import Foundation

struct CodexHookEntry: Codable, Equatable {
    var command: String
    var type: String

    init(command: String, type: String = "command") {
        self.command = command
        self.type = type
    }
}

struct CodexHookEventConfig: Codable, Equatable {
    var matcher: String?
    var hooks: [CodexHookEntry]

    init(matcher: String? = nil, hooks: [CodexHookEntry] = []) {
        self.matcher = matcher
        self.hooks = hooks
    }
}

struct CodexSettings: Equatable {
    // config.toml top-level
    var model: String?
    var modelProvider: String?
    var approvalPolicy: String?
    var sandboxMode: String?
    var modelReasoningEffort: String?
    var modelReasoningSummary: String?
    var fileOpener: String?
    var hideAgentReasoning: Bool?
    var disableResponseStorage: Bool?
    var modelVerbosity: String?

    // [features]
    var features: [String: Bool]

    // [tools]
    var tools: [String: Bool]

    // [history]
    var historyPersistence: String?

    // hooks.json
    var hooks: [String: [CodexHookEventConfig]]?

    init() {
        features = [:]
        tools = [:]
    }
}
