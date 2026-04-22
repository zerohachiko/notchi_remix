import AppKit
import os.log

private let logger = Logger(subsystem: "com.zerohachiko.notchi-remix", category: "SoundService")

@MainActor
@Observable
final class SoundService {
    static let shared = SoundService()

    private static let cooldown: TimeInterval = 2.0
    @ObservationIgnored
    private var lastSoundTimes: [String: Date] = [:]
    @ObservationIgnored
    private var cachedBundleSounds: [String: NSSound] = [:]

    private init() {}

    func playNotificationSound(sessionId: String, isInteractive: Bool) {
        guard isInteractive else {
            logger.debug("Non-interactive session, skipping sound")
            return
        }

        let sound = AppSettings.notificationSound
        guard sound.soundName != nil else {
            logger.debug("Notification sound disabled")
            return
        }

        if TerminalFocusDetector.isTerminalFocused() {
            logger.debug("Terminal focused, skipping notification sound")
            return
        }

        let now = Date()
        if let lastPlayed = lastSoundTimes[sessionId],
           now.timeIntervalSince(lastPlayed) < Self.cooldown {
            logger.debug("Sound cooldown active for session \(sessionId, privacy: .public)")
            return
        }

        lastSoundTimes[sessionId] = now
        play(sound)
    }

    func playHookSound(source: AgentSource, eventType: String, hooks: [String], sessionId: String, isInteractive: Bool) {
        guard isInteractive else { return }

        if TerminalFocusDetector.isTerminalFocused() { return }

        let sourceName = source == .claude ? "claude" : "codex"
        for command in hooks {
            let key = AppSettings.hookSoundKey(source: sourceName, eventType: eventType, command: command)
            if let sound = AppSettings.hookSound(for: key), sound != .none {
                play(sound)
                logger.debug("Playing hook sound \(sound.rawValue, privacy: .public) for \(eventType, privacy: .public)")
                return
            }
        }
    }

    func clearCooldown(for sessionId: String) {
        lastSoundTimes.removeValue(forKey: sessionId)
    }

    func previewSound(_ sound: NotificationSound) {
        guard sound.soundName != nil else { return }
        play(sound)
    }

    private func play(_ sound: NotificationSound) {
        guard let soundName = sound.soundName else { return }

        if sound.isSystemSound {
            playSystemSound(named: soundName)
        } else {
            playBundleSound(named: soundName)
        }
    }

    private func playSystemSound(named soundName: String) {
        guard let nsSound = NSSound(named: NSSound.Name(soundName)) else {
            logger.warning("System sound not found: \(soundName, privacy: .public)")
            return
        }
        nsSound.play()
        logger.debug("Playing system sound: \(soundName, privacy: .public)")
    }

    private func playBundleSound(named soundName: String) {
        if let cached = cachedBundleSounds[soundName] {
            cached.stop()
            cached.play()
            logger.debug("Playing cached bundle sound: \(soundName, privacy: .public)")
            return
        }

        guard let url = Bundle.main.url(forResource: soundName, withExtension: "wav") else {
            logger.warning("Bundle sound not found: \(soundName, privacy: .public).wav")
            return
        }

        guard let nsSound = NSSound(contentsOf: url, byReference: true) else {
            logger.warning("Failed to load bundle sound: \(soundName, privacy: .public)")
            return
        }

        cachedBundleSounds[soundName] = nsSound
        nsSound.play()
        logger.debug("Playing bundle sound: \(soundName, privacy: .public)")
    }
}
