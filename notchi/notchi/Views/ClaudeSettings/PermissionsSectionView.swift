import SwiftUI

struct PermissionsSectionView: View {
    var store: ClaudeSettingsStore

    @State private var isAddingAllow = false
    @State private var isAddingDeny = false
    @State private var newAllowValue = ""
    @State private var newDenyValue = ""

    private var allowList: [String] {
        store.settings.permissions?.allow ?? []
    }

    private var denyList: [String] {
        store.settings.permissions?.deny ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Permissions")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(TerminalColors.secondaryText)

            permissionSubSection(
                label: "Allow",
                color: TerminalColors.green,
                items: allowList,
                type: "allow",
                isAdding: $isAddingAllow,
                newValue: $newAllowValue
            )

            permissionSubSection(
                label: "Deny",
                color: TerminalColors.red,
                items: denyList,
                type: "deny",
                isAdding: $isAddingDeny,
                newValue: $newDenyValue
            )
        }
    }

    private func permissionSubSection(
        label: String,
        color: Color,
        items: [String],
        type: String,
        isAdding: Binding<Bool>,
        newValue: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)

            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 6) {
                    Text(item)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(TerminalColors.primaryText)

                    Spacer()

                    Button(action: { store.removePermission(type: type, index: index) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(TerminalColors.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }

            if isAdding.wrappedValue {
                HStack(spacing: 6) {
                    TextField("Permission", text: newValue)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(TerminalColors.primaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)

                    Button(action: {
                        let trimmed = newValue.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        store.addPermission(type: type, value: trimmed)
                        newValue.wrappedValue = ""
                        isAdding.wrappedValue = false
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(TerminalColors.green)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button(action: { isAdding.wrappedValue.toggle() }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 12))
                    .foregroundColor(TerminalColors.secondaryText)
            }
            .buttonStyle(.plain)
        }
    }
}
