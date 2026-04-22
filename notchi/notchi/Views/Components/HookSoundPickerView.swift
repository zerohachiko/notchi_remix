import SwiftUI

struct HookSoundPickerView: View {
    let hookKey: String
    @State private var selectedSound: NotificationSound?

    init(source: String, eventType: String, command: String) {
        self.hookKey = AppSettings.hookSoundKey(source: source, eventType: eventType, command: command)
        self._selectedSound = State(initialValue: AppSettings.hookSound(for: AppSettings.hookSoundKey(source: source, eventType: eventType, command: command)))
    }

    private var displayText: String {
        selectedSound?.displayName ?? "Muted"
    }

    private var iconName: String {
        selectedSound != nil ? "speaker.wave.2.fill" : "speaker.slash"
    }

    private var iconColor: Color {
        selectedSound != nil ? TerminalColors.green : TerminalColors.dimmedText
    }

    var body: some View {
        Menu {
            Button(action: { selectSound(nil) }) {
                Label {
                    Text("None (Muted)")
                } icon: {
                    if selectedSound == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            ForEach(NotificationSound.allCases.filter { $0 != .none }, id: \.self) { sound in
                Button(action: { selectSound(sound) }) {
                    Label {
                        Text(sound.displayName)
                    } icon: {
                        if selectedSound == sound {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: iconName)
                    .font(.system(size: 9))
                    .foregroundColor(iconColor)

                Text(displayText)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(selectedSound != nil ? TerminalColors.secondaryText : TerminalColors.dimmedText)
                    .lineLimit(1)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 7))
                    .foregroundColor(TerminalColors.dimmedText)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.1))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .fixedSize()
    }

    private func selectSound(_ sound: NotificationSound?) {
        selectedSound = sound
        AppSettings.setHookSound(sound, for: hookKey)
        if let sound {
            SoundService.shared.previewSound(sound)
        }
    }
}
