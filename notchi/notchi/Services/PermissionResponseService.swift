import Foundation
import os.log

private let logger = Logger(subsystem: "com.zerohachiko.notchi-remix", category: "PermissionResponse")

@MainActor
@Observable
final class PermissionResponseService {
    static let shared = PermissionResponseService()

    private(set) var pendingSessionIds: Set<String> = []

    private init() {}

    func markPending(sessionId: String) {
        pendingSessionIds.insert(sessionId)
    }

    func clearPending(sessionId: String) {
        pendingSessionIds.remove(sessionId)
    }

    func hasPending(sessionId: String) -> Bool {
        pendingSessionIds.contains(sessionId)
    }

    func allow(sessionId: String) {
        guard pendingSessionIds.remove(sessionId) != nil else { return }
        let json: [String: Any] = [
            "hookSpecificOutput": [
                "hookEventName": "PermissionRequest",
                "decision": [
                    "behavior": "allow"
                ]
            ]
        ]
        sendResponse(sessionId: sessionId, json: json)
        logger.info("Allowed permission for session \(sessionId, privacy: .public)")
    }

    func deny(sessionId: String) {
        guard pendingSessionIds.remove(sessionId) != nil else { return }
        let json: [String: Any] = [
            "hookSpecificOutput": [
                "hookEventName": "PermissionRequest",
                "decision": [
                    "behavior": "deny",
                    "message": "Denied from Notchi Remix"
                ]
            ]
        ]
        sendResponse(sessionId: sessionId, json: json)
        logger.info("Denied permission for session \(sessionId, privacy: .public)")
    }

    func alwaysAllow(sessionId: String, toolName: String?) {
        guard pendingSessionIds.remove(sessionId) != nil else { return }
        var decision: [String: Any] = ["behavior": "allow"]
        if let tool = toolName {
            decision["updatedPermissions"] = [[
                "type": "addRules",
                "rules": [["toolName": tool]],
                "behavior": "allow",
                "destination": "localSettings"
            ]]
        }
        let json: [String: Any] = [
            "hookSpecificOutput": [
                "hookEventName": "PermissionRequest",
                "decision": decision
            ]
        ]
        sendResponse(sessionId: sessionId, json: json)
        logger.info("Always-allowed permission for session \(sessionId, privacy: .public), tool: \(toolName ?? "unknown", privacy: .public)")
    }

    private func sendResponse(sessionId: String, json: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            logger.error("Failed to serialize permission response")
            return
        }
        SocketServer.shared.respondToPermission(sessionId: sessionId, responseJSON: data)
    }
}
