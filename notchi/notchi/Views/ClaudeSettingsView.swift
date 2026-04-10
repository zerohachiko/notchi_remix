import SwiftUI

struct ClaudeSettingsView: View {
    var store: ClaudeSettingsStore = .shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    basicSection
                    Divider().background(Color.white.opacity(0.08))
                    EnvSectionView(store: store)
                    Divider().background(Color.white.opacity(0.08))
                    PluginsSectionView(store: store)
                    Divider().background(Color.white.opacity(0.08))
                    HooksSectionView(store: store)
                    Divider().background(Color.white.opacity(0.08))
                    PermissionsSectionView(store: store)
                    Divider().background(Color.white.opacity(0.08))
                    MiscSectionView(store: store)
                }
                .padding(.top, 10)
            }
            .scrollIndicators(.hidden)

            Spacer()

            saveStatusBar
                .animation(.easeInOut(duration: 0.2), value: store.saveStatus)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { store.load() }
    }

    private var basicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { store.updateBasicSetting(\.alwaysThinkingEnabled, value: !(store.settings.alwaysThinkingEnabled ?? false)) }) {
                SettingsRowView(icon: "brain.head.profile", title: "Always Thinking") {
                    ToggleSwitch(isOn: store.settings.alwaysThinkingEnabled ?? false)
                }
            }
            .buttonStyle(.plain)

            Button(action: { store.updateBasicSetting(\.rawUrl, value: !(store.settings.rawUrl ?? false)) }) {
                SettingsRowView(icon: "link", title: "Raw URL") {
                    ToggleSwitch(isOn: store.settings.rawUrl ?? false)
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var saveStatusBar: some View {
        switch store.saveStatus {
        case .saved:
            HStack {
                Text("Saved ✓")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(TerminalColors.green)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(TerminalColors.green.opacity(0.1))
            .cornerRadius(6)
            .transition(.opacity)
        case .error(let msg):
            HStack {
                Text(msg)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(TerminalColors.red)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(TerminalColors.red.opacity(0.1))
            .cornerRadius(6)
            .transition(.opacity)
        case .idle:
            EmptyView()
        }
    }
}
