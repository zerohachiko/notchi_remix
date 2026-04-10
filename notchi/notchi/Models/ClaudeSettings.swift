import Foundation

struct HookEntry: Codable, Equatable {
    var command: String
    var type: String
    var timeout: Int?

    init(command: String, type: String = "command", timeout: Int? = nil) {
        self.command = command
        self.type = type
        self.timeout = timeout
    }
}

struct HookEventConfig: Codable, Equatable {
    var matcher: String?
    var hooks: [HookEntry]

    init(matcher: String? = nil, hooks: [HookEntry] = []) {
        self.matcher = matcher
        self.hooks = hooks
    }
}

struct PermissionsConfig: Codable, Equatable {
    var allow: [String]
    var deny: [String]

    init(allow: [String] = [], deny: [String] = []) {
        self.allow = allow
        self.deny = deny
    }
}

struct StatusLineConfig: Codable, Equatable {
    var command: String
    var type: String

    init(command: String, type: String = "command") {
        self.command = command
        self.type = type
    }
}

struct MarketplaceSource: Codable, Equatable {
    var repo: String
    var source: String
}

struct MarketplaceConfig: Codable, Equatable {
    var source: MarketplaceSource
}

struct ClaudeSettings: Equatable {
    var alwaysThinkingEnabled: Bool?
    var rawUrl: Bool?
    var env: [String: String]?
    var enabledPlugins: [String: Bool]?
    var hooks: [String: [HookEventConfig]]?
    var permissions: PermissionsConfig?
    var statusLine: StatusLineConfig?
    var extraKnownMarketplaces: [String: MarketplaceConfig]?
    var extraFields: [String: Any] = [:]

    init(
        alwaysThinkingEnabled: Bool? = nil,
        rawUrl: Bool? = nil,
        env: [String: String]? = nil,
        enabledPlugins: [String: Bool]? = nil,
        hooks: [String: [HookEventConfig]]? = nil,
        permissions: PermissionsConfig? = nil,
        statusLine: StatusLineConfig? = nil,
        extraKnownMarketplaces: [String: MarketplaceConfig]? = nil,
        extraFields: [String: Any] = [:]
    ) {
        self.alwaysThinkingEnabled = alwaysThinkingEnabled
        self.rawUrl = rawUrl
        self.env = env
        self.enabledPlugins = enabledPlugins
        self.hooks = hooks
        self.permissions = permissions
        self.statusLine = statusLine
        self.extraKnownMarketplaces = extraKnownMarketplaces
        self.extraFields = extraFields
    }

    static func == (lhs: ClaudeSettings, rhs: ClaudeSettings) -> Bool {
        lhs.alwaysThinkingEnabled == rhs.alwaysThinkingEnabled
            && lhs.rawUrl == rhs.rawUrl
            && lhs.env == rhs.env
            && lhs.enabledPlugins == rhs.enabledPlugins
            && lhs.hooks == rhs.hooks
            && lhs.permissions == rhs.permissions
            && lhs.statusLine == rhs.statusLine
            && lhs.extraKnownMarketplaces == rhs.extraKnownMarketplaces
    }
}

extension ClaudeSettings: Codable {
    enum CodingKeys: String, CodingKey {
        case alwaysThinkingEnabled
        case rawUrl
        case env
        case enabledPlugins
        case hooks
        case permissions
        case statusLine
        case extraKnownMarketplaces
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        alwaysThinkingEnabled = try container.decodeIfPresent(Bool.self, forKey: .alwaysThinkingEnabled)
        rawUrl = try container.decodeIfPresent(Bool.self, forKey: .rawUrl)
        env = try container.decodeIfPresent([String: String].self, forKey: .env)
        enabledPlugins = try container.decodeIfPresent([String: Bool].self, forKey: .enabledPlugins)
        hooks = try container.decodeIfPresent([String: [HookEventConfig]].self, forKey: .hooks)
        permissions = try container.decodeIfPresent(PermissionsConfig.self, forKey: .permissions)
        statusLine = try container.decodeIfPresent(StatusLineConfig.self, forKey: .statusLine)
        extraKnownMarketplaces = try container.decodeIfPresent([String: MarketplaceConfig].self, forKey: .extraKnownMarketplaces)

        let knownKeys = Set(CodingKeys.allCases.map(\.rawValue))
        guard let rawData = decoder.userInfo[.rawJSONData] as? Data,
              let fullDict = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any] else {
            extraFields = [:]
            return
        }
        extraFields = fullDict.filter { !knownKeys.contains($0.key) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(alwaysThinkingEnabled, forKey: .alwaysThinkingEnabled)
        try container.encodeIfPresent(rawUrl, forKey: .rawUrl)
        try container.encodeIfPresent(env, forKey: .env)
        try container.encodeIfPresent(enabledPlugins, forKey: .enabledPlugins)
        try container.encodeIfPresent(hooks, forKey: .hooks)
        try container.encodeIfPresent(permissions, forKey: .permissions)
        try container.encodeIfPresent(statusLine, forKey: .statusLine)
        try container.encodeIfPresent(extraKnownMarketplaces, forKey: .extraKnownMarketplaces)
    }
}

extension ClaudeSettings.CodingKeys: CaseIterable {}

extension CodingUserInfoKey {
    static let rawJSONData = CodingUserInfoKey(rawValue: "rawJSONData")!
}
