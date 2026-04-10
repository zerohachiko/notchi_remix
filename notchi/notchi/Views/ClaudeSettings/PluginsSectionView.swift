import SwiftUI

struct PluginsSectionView: View {
    var store: ClaudeSettingsStore

    @State private var isAdding = false
    @State private var newPluginName = ""

    private var sortedPlugins: [(key: String, value: Bool)] {
        (store.settings.enabledPlugins ?? [:]).sorted { $0.key < $1.key }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Plugins")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(TerminalColors.secondaryText)

            ForEach(sortedPlugins, id: \.key) { name, enabled in
                pluginRow(name: name, enabled: enabled)
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

    private func pluginRow(name: String, enabled: Bool) -> some View {
        HStack(spacing: 6) {
            Button(action: { store.setPlugin(name, enabled: !enabled) }) {
                HStack {
                    Text(name)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(TerminalColors.primaryText)

                    Spacer()

                    ToggleSwitch(isOn: enabled)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: { store.removePlugin(name) }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(TerminalColors.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
    }

    private var addRow: some View {
        HStack(spacing: 6) {
            TextField("Plugin name", text: $newPluginName)
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
        let trimmed = newPluginName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.setPlugin(trimmed, enabled: true)
        newPluginName = ""
        isAdding = false
    }
}
