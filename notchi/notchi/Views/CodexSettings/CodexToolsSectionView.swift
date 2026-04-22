import SwiftUI

struct CodexToolsSectionView: View {
    var store: CodexSettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Features & Tools")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(TerminalColors.secondaryText)

            ForEach(store.settings.features.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                Button(action: { store.updateFeature(key, value: !value) }) {
                    SettingsRowView(icon: "flag", title: key) {
                        ToggleSwitch(isOn: value)
                    }
                }
                .buttonStyle(.plain)
            }

            ForEach(store.settings.tools.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                Button(action: { store.updateTool(key, value: !value) }) {
                    SettingsRowView(icon: "wrench", title: key) {
                        ToggleSwitch(isOn: value)
                    }
                }
                .buttonStyle(.plain)
            }

            if let persistence = store.settings.historyPersistence {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12))
                        .foregroundColor(TerminalColors.secondaryText)
                        .frame(width: 20)

                    Text("History")
                        .font(.system(size: 12))
                        .foregroundColor(TerminalColors.primaryText)

                    Spacer()

                    Text(persistence)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(TerminalColors.secondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                }
                .padding(.vertical, 4)
            }

            if store.settings.features.isEmpty && store.settings.tools.isEmpty && store.settings.historyPersistence == nil {
                Text("No features or tools configured")
                    .font(.system(size: 11))
                    .foregroundColor(TerminalColors.dimmedText)
                    .padding(.vertical, 4)
            }
        }
    }
}
