import SwiftUI

struct CodexSettingsView: View {
    var store: CodexSettingsStore = .shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CodexBasicSectionView(store: store)
                    Divider().background(Color.white.opacity(0.08))
                    CodexToolsSectionView(store: store)
                    Divider().background(Color.white.opacity(0.08))
                    CodexHooksSectionView(store: store)
                }
                .padding(.top, 10)
            }
            .scrollIndicators(.hidden)

            Spacer()

            bottomBar
                .animation(.easeInOut(duration: 0.2), value: store.isDirty)
                .animation(.easeInOut(duration: 0.2), value: store.saveStatus)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { store.load() }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if store.isDirty {
            HStack(spacing: 8) {
                Button(action: { store.discardChanges() }) {
                    Text("Discard")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(TerminalColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: { store.commitSave() }) {
                    Text("Confirm")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(TerminalColors.green)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            switch store.saveStatus {
            case .saved:
                HStack {
                    Text("Saved")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(TerminalColors.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(TerminalColors.green.opacity(0.1))
                .cornerRadius(6)
                .padding(.bottom, 8)
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
                .padding(.bottom, 8)
                .transition(.opacity)
            case .idle:
                EmptyView()
            }
        }
    }
}
