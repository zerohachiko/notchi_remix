import SwiftUI

struct CodexBasicSectionView: View {
    var store: CodexSettingsStore

    @State private var modelText: String = ""

    private let approvalPolicies = ["untrusted", "on-failure", "on-request", "never"]
    private let sandboxModes = ["read-only", "workspace-write", "danger-full-access"]
    private let reasoningEfforts = ["minimal", "low", "medium", "high", "none"]
    private let reasoningSummaries = ["auto", "concise", "detailed", "none"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            modelField

            pickerRow(label: "Approval Policy", key: "approval_policy",
                      current: store.settings.approvalPolicy, options: approvalPolicies)

            pickerRow(label: "Sandbox Mode", key: "sandbox_mode",
                      current: store.settings.sandboxMode, options: sandboxModes)

            pickerRow(label: "Reasoning Effort", key: "model_reasoning_effort",
                      current: store.settings.modelReasoningEffort, options: reasoningEfforts)

            pickerRow(label: "Reasoning Summary", key: "model_reasoning_summary",
                      current: store.settings.modelReasoningSummary, options: reasoningSummaries)

            Button(action: {
                store.updateTopLevelBool("hide_agent_reasoning", value: !(store.settings.hideAgentReasoning ?? false))
            }) {
                SettingsRowView(icon: "eye.slash", title: "Hide Reasoning") {
                    ToggleSwitch(isOn: store.settings.hideAgentReasoning ?? false)
                }
            }
            .buttonStyle(.plain)

            Button(action: {
                store.updateTopLevelBool("disable_response_storage", value: !(store.settings.disableResponseStorage ?? false))
            }) {
                SettingsRowView(icon: "externaldrive.badge.minus", title: "Disable Storage") {
                    ToggleSwitch(isOn: store.settings.disableResponseStorage ?? false)
                }
            }
            .buttonStyle(.plain)
        }
        .onAppear { modelText = store.settings.model ?? "" }
        .onChange(of: store.settings.model) { _, newValue in
            modelText = newValue ?? ""
        }
    }

    private var modelField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Model")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(TerminalColors.secondaryText)

            TextField("", text: $modelText)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(TerminalColors.primaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
                .onSubmit {
                    store.updateTopLevel("model", value: modelText.isEmpty ? nil : modelText)
                }
                .overlay(alignment: .leading) {
                    if modelText.isEmpty {
                        Text("gpt-5")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(TerminalColors.dimmedText)
                            .padding(.leading, 8)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private func pickerRow(label: String, key: String, current: String?, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(TerminalColors.dimmedText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(options, id: \.self) { option in
                        let isSelected = current == option
                        Button(action: { store.updateTopLevel(key, value: option) }) {
                            Text(option)
                                .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? TerminalColors.green : TerminalColors.secondaryText)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(isSelected ? TerminalColors.green.opacity(0.15) : Color.white.opacity(0.06))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
