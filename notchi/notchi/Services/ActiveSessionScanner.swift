import Foundation
import os.log

private let logger = Logger(subsystem: "com.zerohachiko.notchi-remix", category: "ActiveSessionScanner")

struct ClaudeSessionFile: Decodable {
    let pid: Int
    let sessionId: String
    let cwd: String
    let startedAt: Int64
    let kind: String
    let entrypoint: String?
}

@MainActor
enum ActiveSessionScanner {

    private static let sessionsDirectory: String = {
        NSHomeDirectory() + "/.claude/sessions"
    }()

    static func scanAndRestore() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: sessionsDirectory) else {
            logger.debug("No ~/.claude/sessions directory found")
            return
        }

        guard let files = try? fm.contentsOfDirectory(atPath: sessionsDirectory) else {
            logger.warning("Failed to list ~/.claude/sessions")
            return
        }

        let jsonFiles = files.filter { $0.hasSuffix(".json") }
        guard !jsonFiles.isEmpty else {
            logger.debug("No session files found")
            return
        }

        var restoredCount = 0

        for file in jsonFiles {
            let filePath = sessionsDirectory + "/" + file

            guard let data = fm.contents(atPath: filePath),
                  let session = try? JSONDecoder().decode(ClaudeSessionFile.self, from: data) else {
                logger.debug("Skipping unparseable session file: \(file, privacy: .public)")
                continue
            }

            guard isProcessAlive(pid: session.pid) else {
                logger.debug("Skipping dead session pid=\(session.pid) id=\(session.sessionId, privacy: .public)")
                continue
            }

            guard SessionStore.shared.sessions[session.sessionId] == nil else {
                logger.debug("Session already tracked: \(session.sessionId, privacy: .public)")
                continue
            }

            let isInteractive = session.kind == "interactive"
            let syntheticEvent = HookEvent(
                sessionId: session.sessionId,
                cwd: session.cwd,
                event: "SessionStart",
                status: "waiting_for_input",
                pid: session.pid,
                tty: nil,
                tool: nil,
                toolInput: nil,
                toolUseId: nil,
                userPrompt: nil,
                permissionMode: nil,
                interactive: isInteractive,
                lastAssistantMessage: nil,
                sourceApp: nil
            )

            NotchiStateMachine.shared.handleEvent(syntheticEvent)
            restoredCount += 1
            logger.info("Restored existing session: \(session.sessionId, privacy: .public) pid=\(session.pid) cwd=\(session.cwd, privacy: .public)")
        }

        if restoredCount > 0 {
            logger.info("Restored \(restoredCount) existing Claude Code session(s)")
        } else {
            logger.debug("No active Claude Code sessions found")
        }
    }

    private static func isProcessAlive(pid: Int) -> Bool {
        kill(Int32(pid), 0) == 0
    }
}
