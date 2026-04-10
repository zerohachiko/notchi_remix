import SwiftUI

struct MiscSectionView: View {
    var store: ClaudeSettingsStore

    @State private var statusCommand: String = ""
    @State private var isAddingMarketplace = false
    @State private var newMarketplaceName = ""
    @State private var newMarketplaceRepo = ""

    private var sortedMarketplaces: [(key: String, value: MarketplaceConfig)] {
        (store.settings.extraKnownMarketplaces ?? [:]).sorted { $0.key < $1.key }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            statusLineSection

            marketplacesSection
        }
        .onAppear {
            statusCommand = store.settings.statusLine?.command ?? ""
        }
        .onChange(of: store.settings.statusLine?.command) { _, newValue in
            statusCommand = newValue ?? ""
        }
    }

    private var statusLineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status Line")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(TerminalColors.secondaryText)

            Text("Type: command")
                .font(.system(size: 10))
                .foregroundColor(TerminalColors.dimmedText)

            TextField("", text: $statusCommand)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(TerminalColors.primaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
                .onSubmit { store.updateStatusLine(command: statusCommand) }
        }
    }

    private var marketplacesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Extra Marketplaces")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(TerminalColors.secondaryText)

            ForEach(sortedMarketplaces, id: \.key) { name, config in
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(TerminalColors.primaryText)

                    Text(config.source.repo)
                        .font(.system(size: 10))
                        .foregroundColor(TerminalColors.dimmedText)

                    Spacer()

                    Button(action: { store.removeMarketplace(name: name) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(TerminalColors.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }

            if isAddingMarketplace {
                addMarketplaceRow
            }

            Button(action: { isAddingMarketplace.toggle() }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 12))
                    .foregroundColor(TerminalColors.secondaryText)
            }
            .buttonStyle(.plain)
        }
    }

    private var addMarketplaceRow: some View {
        HStack(spacing: 6) {
            TextField("Name", text: $newMarketplaceName)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(TerminalColors.primaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)

            TextField("Repo", text: $newMarketplaceRepo)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(TerminalColors.primaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
                .onSubmit { commitAddMarketplace() }

            Button(action: commitAddMarketplace) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(TerminalColors.green)
            }
            .buttonStyle(.plain)
        }
    }

    private func commitAddMarketplace() {
        let trimmedName = newMarketplaceName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRepo = newMarketplaceRepo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedRepo.isEmpty else { return }
        store.addMarketplace(name: trimmedName, repo: trimmedRepo, source: "github")
        newMarketplaceName = ""
        newMarketplaceRepo = ""
        isAddingMarketplace = false
    }
}
