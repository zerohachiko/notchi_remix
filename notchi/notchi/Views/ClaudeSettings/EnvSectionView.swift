import SwiftUI

struct EnvSectionView: View {
    var store: ClaudeSettingsStore

    @State private var revealedKeys: Set<String> = []
    @State private var isAdding = false
    @State private var newKey = ""
    @State private var newValue = ""

    private var sortedEnvVars: [(key: String, value: String)] {
        (store.settings.env ?? [:]).sorted { $0.key < $1.key }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Environment Variables")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(TerminalColors.secondaryText)

            ForEach(sortedEnvVars, id: \.key) { key, value in
                envRow(key: key, value: value)
            }

            if isAdding {
                addRow
            }

            Button(action: { isAdding.toggle() }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 12))
                    .foregroundColor(TerminalColors.secondaryText)
            }
            .buttonStyle(.plain)
        }
    }

    private func isSensitive(_ key: String) -> Bool {
        let upper = key.uppercased()
        return upper.contains("TOKEN") || upper.contains("KEY") || upper.contains("SECRET")
    }

    private func envRow(key: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(key)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(TerminalColors.secondaryText)

            if isSensitive(key) && !revealedKeys.contains(key) {
                Text("••••")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(TerminalColors.primaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
            } else {
                TextField("", text: Binding(
                    get: { value },
                    set: { store.updateEnvVar(key: key, value: $0) }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(TerminalColors.primaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
                .onSubmit { store.updateEnvVar(key: key, value: value) }
            }

            if isSensitive(key) {
                Button(action: {
                    if revealedKeys.contains(key) {
                        revealedKeys.remove(key)
                    } else {
                        revealedKeys.insert(key)
                    }
                }) {
                    Image(systemName: revealedKeys.contains(key) ? "eye.slash" : "eye")
                        .font(.system(size: 12))
                        .foregroundColor(TerminalColors.secondaryText)
                }
                .buttonStyle(.plain)
            }

            Button(action: { store.removeEnvVar(key: key) }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(TerminalColors.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
    }

    private var addRow: some View {
        HStack(spacing: 6) {
            TextField("Key", text: $newKey)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(TerminalColors.primaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)

            TextField("Value", text: $newValue)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(TerminalColors.primaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)

            Button(action: commitAdd) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(TerminalColors.green)
            }
            .buttonStyle(.plain)
        }
    }

    private func commitAdd() {
        let trimmedKey = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return }
        store.addEnvVar(key: trimmedKey, value: newValue)
        newKey = ""
        newValue = ""
        isAdding = false
    }
}
