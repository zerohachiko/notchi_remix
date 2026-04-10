import SwiftUI

struct HooksSectionView: View {
    var store: ClaudeSettingsStore

    @State private var addingEventType: String?
    @State private var newCommand = ""

    private var sortedHooks: [(key: String, value: [HookEventConfig])] {
        (store.settings.hooks ?? [:]).sorted { $0.key < $1.key }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hooks")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(TerminalColors.secondaryText)

            ForEach(sortedHooks, id: \.key) { eventType, configs in
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(configs.enumerated()), id: \.offset) { ci, config in
                            ForEach(Array(config.hooks.enumerated()), id: \.offset) { hi, hook in
                                HookEntryRow(
                                    store: store,
                                    eventType: eventType,
                                    config: config,
                                    ci: ci,
                                    hi: hi,
                                    hook: hook
                                )
                            }
                        }

                        if addingEventType == eventType {
                            addHookRow(eventType: eventType)
                        }

                        Button(action: { addingEventType = eventType; newCommand = "" }) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 12))
                                .foregroundColor(TerminalColors.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                } label: {
                    HStack(spacing: 6) {
                        Text(eventType)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(TerminalColors.primaryText)

                        let count = configs.reduce(0) { $0 + $1.hooks.count }
                        Text("\(count)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(TerminalColors.secondaryText)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(3)
                    }
                }
                .accentColor(TerminalColors.secondaryText)
            }
        }
    }

    private func addHookRow(eventType: String) -> some View {
        HStack(spacing: 6) {
            TextField("Command", text: $newCommand)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(TerminalColors.primaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
                .onSubmit { commitAddHook(eventType: eventType) }

            Button(action: { commitAddHook(eventType: eventType) }) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(TerminalColors.green)
            }
            .buttonStyle(.plain)
        }
    }

    private func commitAddHook(eventType: String) {
        let trimmed = newCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addHookEntry(eventType: eventType, entry: HookEntry(command: trimmed))
        newCommand = ""
        addingEventType = nil
    }
}

private struct HookEntryRow: View {
    var store: ClaudeSettingsStore
    let eventType: String
    let config: HookEventConfig
    let ci: Int
    let hi: Int
    let hook: HookEntry

    @State private var command: String = ""

    private var isNotchi: Bool {
        command.contains("notchi-hook.sh")
    }

    var body: some View {
        HStack(spacing: 6) {
            TextField("", text: $command)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(TerminalColors.primaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
                .onSubmit {
                    store.removeHookEntry(eventType: eventType, configIndex: ci, hookIndex: hi)
                    store.addHookEntry(eventType: eventType, entry: HookEntry(command: command, timeout: hook.timeout), matcher: config.matcher)
                }

            if isNotchi {
                Text("Notchi Remix")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(TerminalColors.green)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(TerminalColors.green.opacity(0.15))
                    .cornerRadius(3)
            }

            if let timeout = hook.timeout {
                Text("timeout: \(timeout)")
                    .font(.system(size: 9))
                    .foregroundColor(TerminalColors.dimmedText)
            }

            if let matcher = config.matcher {
                Text("matcher: \(matcher)")
                    .font(.system(size: 9))
                    .foregroundColor(TerminalColors.dimmedText)
            }

            if !isNotchi {
                Button(action: { store.removeHookEntry(eventType: eventType, configIndex: ci, hookIndex: hi) }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(TerminalColors.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear { command = hook.command }
        .onChange(of: hook.command) { _, newValue in command = newValue }
    }
}
