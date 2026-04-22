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

    // MARK: - Codex Session Scanning

    private static let codexDirectory: String = {
        NSHomeDirectory() + "/.codex"
    }()

    static func scanAndRestoreCodex() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: codexDirectory) else {
            logger.debug("No ~/.codex directory found")
            return
        }

        let logsDbPath = codexDirectory + "/logs_2.sqlite"
        let stateDbPath = codexDirectory + "/state_5.sqlite"

        guard fm.fileExists(atPath: logsDbPath),
              fm.fileExists(atPath: stateDbPath) else {
            logger.debug("Codex SQLite databases not found")
            return
        }

        // Step 1: Find thread IDs associated with alive Codex processes
        let activeThreadIds = findActiveCodexThreadIds(logsDbPath: logsDbPath)
        guard !activeThreadIds.isEmpty else {
            logger.debug("No active Codex threads found")
            return
        }

        // Step 2: Get thread details (cwd) from state DB
        let threads = fetchCodexThreadDetails(stateDbPath: stateDbPath, threadIds: activeThreadIds)

        // Step 3: Inject synthetic SessionStart events
        var restoredCount = 0
        for thread in threads {
            guard SessionStore.shared.sessions[thread.id] == nil else {
                logger.debug("Codex session already tracked: \(thread.id, privacy: .public)")
                continue
            }

            let syntheticEvent = HookEvent(
                sessionId: thread.id,
                cwd: thread.cwd,
                event: "SessionStart",
                status: "waiting_for_input",
                pid: nil,
                tty: nil,
                tool: nil,
                toolInput: nil,
                toolUseId: nil,
                userPrompt: nil,
                permissionMode: nil,
                interactive: true,
                lastAssistantMessage: nil,
                sourceApp: .codex
            )

            NotchiStateMachine.shared.handleEvent(syntheticEvent)
            restoredCount += 1
            logger.info("Restored existing Codex session: \(thread.id, privacy: .public) cwd=\(thread.cwd, privacy: .public)")
        }

        if restoredCount > 0 {
            logger.info("Restored \(restoredCount) existing Codex session(s)")
        } else {
            logger.debug("No active Codex sessions to restore")
        }
    }

    private struct CodexThread {
        let id: String
        let cwd: String
    }

    /// Query logs_2.sqlite for recent thread_ids whose associated process PID is still alive.
    /// The process_uuid column format is "pid:PID:UUID".
    private static func findActiveCodexThreadIds(logsDbPath: String) -> Set<String> {
        let query = """
            SELECT DISTINCT process_uuid, thread_id FROM logs \
            WHERE thread_id IS NOT NULL AND thread_id != '' \
            AND ts > (strftime('%s','now') - 600) \
            ORDER BY ts DESC;
            """

        guard let output = runSQLiteQuery(dbPath: logsDbPath, query: query) else {
            return []
        }

        var activeThreadIds = Set<String>()

        for line in output.split(separator: "\n") {
            let parts = line.split(separator: "|", maxSplits: 1)
            guard parts.count == 2 else { continue }

            let processUuid = String(parts[0])
            let threadId = String(parts[1])

            if let pid = extractPid(from: processUuid), isProcessAlive(pid: pid) {
                activeThreadIds.insert(threadId)
            }
        }

        return activeThreadIds
    }

    /// Fetch cwd for the given thread IDs from state_5.sqlite.
    private static func fetchCodexThreadDetails(stateDbPath: String, threadIds: Set<String>) -> [CodexThread] {
        let idList = threadIds.map { "'\($0.replacingOccurrences(of: "'", with: "''"))'" }.joined(separator: ",")
        let query = "SELECT id, cwd FROM threads WHERE id IN (\(idList));"

        guard let output = runSQLiteQuery(dbPath: stateDbPath, query: query) else {
            return []
        }

        var threads: [CodexThread] = []
        for line in output.split(separator: "\n") {
            let parts = line.split(separator: "|", maxSplits: 1)
            guard parts.count == 2 else { continue }
            threads.append(CodexThread(id: String(parts[0]), cwd: String(parts[1])))
        }

        return threads
    }

    /// Extract PID from process_uuid format "pid:PID:UUID".
    private static func extractPid(from processUuid: String) -> Int? {
        let parts = processUuid.split(separator: ":")
        guard parts.count >= 2, parts[0] == "pid" else { return nil }
        return Int(parts[1])
    }

    /// Run a sqlite3 query and return the stdout output.
    private static func runSQLiteQuery(dbPath: String, query: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = ["-separator", "|", "-readonly", dbPath, query]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            logger.warning("Failed to run sqlite3: \(error.localizedDescription)")
            return nil
        }

        guard process.terminationStatus == 0 else {
            logger.debug("sqlite3 exited with code \(process.terminationStatus)")
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let result = String(data: data, encoding: .utf8), !result.isEmpty else {
            return nil
        }

        return result
    }

    private static func isProcessAlive(pid: Int) -> Bool {
        kill(Int32(pid), 0) == 0
    }
}
