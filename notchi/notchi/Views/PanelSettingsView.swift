import ServiceManagement
import SwiftUI

struct PanelSettingsView: View {
    var onOpenClaudeSettings: (() -> Void)? = nil
    var onOpenCodexSettings: (() -> Void)? = nil
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var hooksInstalled = HookInstaller.isInstalled()
    @State private var hooksError = false
    @State private var codexHooksInstalled = HookInstaller.isCodexInstalled()
    @State private var codexHooksError = false
    @State private var codexAvailable = HookInstaller.codexAvailable()
    @State private var apiKeyInput = AppSettings.anthropicApiKey ?? ""
    @ObservedObject private var updateManager = UpdateManager.shared
    private var usageConnected: Bool { ClaudeUsageService.shared.isConnected }
    private var hasApiKey: Bool { !apiKeyInput.isEmpty }

    private var hookStatusText: String {
        if hooksError { return "Error" }
        if hooksInstalled { return "Installed" }
        return "Not Installed"
    }

    private var hookStatusColor: Color {
        hooksInstalled && !hooksError ? TerminalColors.green : TerminalColors.red
    }

    private var codexHookStatusText: String {
        if !codexAvailable { return "Not Found" }
        if codexHooksError { return "Error" }
        if codexHooksInstalled { return "Installed" }
        return "Not Installed"
    }

    private var codexHookStatusColor: Color {
        if !codexAvailable { return TerminalColors.dimmedText }
        return codexHooksInstalled && !codexHooksError ? TerminalColors.green : TerminalColors.red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    displaySection
                    Divider().background(Color.white.opacity(0.08))
                    togglesSection
                    Divider().background(Color.white.opacity(0.08))
                    actionsSection
                }
                .padding(.top, 10)
            }
            .scrollIndicators(.hidden)

            Spacer()

            quitSection
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScreenPickerRow(screenSelector: ScreenSelector.shared)

            SoundPickerView()

            WeatherDebugSection()
        }
    }

    private var togglesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: toggleLaunchAtLogin) {
                SettingsRowView(icon: "power", title: "Launch at Login") {
                    ToggleSwitch(isOn: launchAtLogin)
                }
            }
            .buttonStyle(.plain)

            Button(action: installHooksIfNeeded) {
                SettingsRowView(icon: "terminal", title: "Claude Hooks") {
                    statusBadge(hookStatusText, color: hookStatusColor)
                }
            }
            .buttonStyle(.plain)

            Button(action: installCodexHooksIfNeeded) {
                SettingsRowView(icon: "terminal.fill", title: "Codex Hooks") {
                    statusBadge(codexHookStatusText, color: codexHookStatusColor)
                }
            }
            .buttonStyle(.plain)
            .disabled(!codexAvailable)

            Button(action: connectUsage) {
                SettingsRowView(icon: "gauge.with.dots.needle.33percent", title: "Claude Usage") {
                    statusBadge(
                        usageConnected ? "Connected" : "Not Connected",
                        color: usageConnected ? TerminalColors.green : TerminalColors.red
                    )
                }
            }
            .buttonStyle(.plain)

            apiKeyRow
        }
    }

    private var apiKeyRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            SettingsRowView(icon: "brain", title: "Emotion Analysis") {
                statusBadge(
                    hasApiKey ? "Active" : "No Key",
                    color: hasApiKey ? TerminalColors.green : TerminalColors.red
                )
            }

            HStack(spacing: 6) {
                SecureField("", text: $apiKeyInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(TerminalColors.primaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                    .onSubmit { saveApiKey() }
                    .overlay(alignment: .leading) {
                        if apiKeyInput.isEmpty {
                            Text("Anthropic API Key")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(TerminalColors.dimmedText)
                                .padding(.leading, 8)
                                .allowsHitTesting(false)
                        }
                    }

                Button(action: saveApiKey) {
                    Image(systemName: hasApiKey ? "checkmark.circle.fill" : "arrow.right.circle")
                        .font(.system(size: 14))
                        .foregroundColor(hasApiKey ? TerminalColors.green : TerminalColors.dimmedText)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 28)
        }
    }

    private func saveApiKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        AppSettings.anthropicApiKey = trimmed.isEmpty ? nil : trimmed
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { onOpenClaudeSettings?() }) {
                SettingsRowView(icon: "doc.text.magnifyingglass", title: "Claude Code Settings") {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(TerminalColors.dimmedText)
                }
            }
            .buttonStyle(.plain)

            Button(action: { onOpenCodexSettings?() }) {
                SettingsRowView(icon: "doc.text.magnifyingglass", title: "Codex Settings") {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(codexAvailable ? TerminalColors.dimmedText : TerminalColors.dimmedText.opacity(0.4))
                }
            }
            .buttonStyle(.plain)
            .disabled(!codexAvailable)

            Button(action: handleUpdatesAction) {
                SettingsRowView(icon: "arrow.triangle.2.circlepath", title: "Check for Updates") {
                    updateStatusView
                }
            }
            .buttonStyle(.plain)

            Button(action: openGitHubRepo) {
                SettingsRowView(icon: "star", title: "Star on GitHub") {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10))
                        .foregroundColor(TerminalColors.dimmedText)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func openGitHubRepo() {
        NSWorkspace.shared.open(URL(string: "https://github.com/sk-ruban/notchi")!)
    }

    private func openLatestReleasePage() {
        NSWorkspace.shared.open(URL(string: "https://github.com/sk-ruban/notchi/releases/latest")!)
    }

    private var quitSection: some View {
        Button(action: {
            NSApplication.shared.terminate(nil)
        }) {
            HStack {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 13))
                Text("Quit Notchi Remix")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(TerminalColors.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(TerminalColors.red.opacity(0.1))
            .contentShape(Rectangle())
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 8)
    }

    private func toggleLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            launchAtLogin = SMAppService.mainApp.status == .enabled
        } catch {
            print("Failed to toggle launch at login: \(error)")
        }
    }

    private func connectUsage() {
        ClaudeUsageService.shared.connectAndStartPolling()
    }

    private func handleUpdatesAction() {
        if case .upToDate = updateManager.state {
            openLatestReleasePage()
        } else {
            updateManager.checkForUpdates()
        }
    }

    private func installHooksIfNeeded() {
        guard !hooksInstalled else { return }
        hooksError = false
        let success = HookInstaller.installIfNeeded()
        if success {
            hooksInstalled = HookInstaller.isInstalled()
        } else {
            hooksError = true
        }
    }

    private func installCodexHooksIfNeeded() {
        guard codexAvailable, !codexHooksInstalled else { return }
        codexHooksError = false
        let success = HookInstaller.installCodexIfNeeded()
        if success {
            codexHooksInstalled = HookInstaller.isCodexInstalled()
        } else {
            codexHooksError = true
        }
    }

    private func statusBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
            .frame(maxWidth: 160, alignment: .trailing)
    }

    @ViewBuilder
    private var updateStatusView: some View {
        switch updateManager.state {
        case .checking:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.mini)
                Text("Checking...")
                    .font(.system(size: 10))
                    .foregroundColor(TerminalColors.dimmedText)
            }
        case .upToDate:
            statusBadge("Up to date", color: TerminalColors.green)
        case .updateAvailable:
            statusBadge("Update available", color: TerminalColors.amber)
        case .downloading:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.mini)
                Text("Downloading...")
                    .font(.system(size: 10))
                    .foregroundColor(TerminalColors.dimmedText)
            }
        case .readyToInstall:
            statusBadge("Ready to install", color: TerminalColors.green)
        case .error(let failure):
            statusBadge(failure.label, color: TerminalColors.red)
        case .idle:
            Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                .font(.system(size: 10))
                .foregroundColor(TerminalColors.dimmedText)
        }
    }
}

struct SettingsRowView<Trailing: View>: View {
    let icon: String
    let title: String
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(TerminalColors.secondaryText)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(TerminalColors.primaryText)

            Spacer()

            trailing()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct ToggleSwitch: View {
    let isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? TerminalColors.green : Color.white.opacity(0.15))
                .frame(width: 32, height: 18)

            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)
                .padding(2)
        }
        .animation(.easeInOut(duration: 0.15), value: isOn)
    }
}

#Preview {
    PanelSettingsView()
        .frame(width: 402, height: 400)
        .background(Color.black)
}

// MARK: - Weather Debug Section

struct WeatherDebugSection: View {
    private var weatherService: WeatherService { .shared }
    @State private var isDebugEnabled = WeatherService.shared.isDebugMode
    @State private var selectedCondition: WeatherCondition = WeatherService.shared.condition
    @State private var isNight: Bool = WeatherService.shared.isNight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: toggleDebug) {
                SettingsRowView(icon: "cloud.sun", title: "Weather Debug") {
                    ToggleSwitch(isOn: isDebugEnabled)
                }
            }
            .buttonStyle(.plain)

            if isDebugEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    // Weather condition picker
                    HStack(spacing: 0) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(WeatherCondition.allCases, id: \.rawValue) { condition in
                                    weatherChip(condition)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }

                    // Day/Night toggle
                    Button(action: toggleNight) {
                        HStack(spacing: 6) {
                            Image(systemName: isNight ? "moon.fill" : "sun.max.fill")
                                .font(.system(size: 11))
                                .foregroundColor(isNight ? TerminalColors.iMessageBlue : TerminalColors.amber)
                            Text(isNight ? "Night" : "Day")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(TerminalColors.primaryText)
                            Spacer()
                            ToggleSwitch(isOn: isNight)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 28)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isDebugEnabled)
    }

    private func weatherChip(_ condition: WeatherCondition) -> some View {
        let isSelected = selectedCondition == condition
        return Button(action: {
            selectedCondition = condition
            applyOverride()
        }) {
            Text(condition.displayName)
                .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : TerminalColors.secondaryText)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(isSelected ? TerminalColors.iMessageBlue.opacity(0.6) : Color.white.opacity(0.06))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func toggleDebug() {
        isDebugEnabled.toggle()
        if isDebugEnabled {
            applyOverride()
        } else {
            weatherService.clearDebugOverride()
        }
    }

    private func toggleNight() {
        isNight.toggle()
        applyOverride()
    }

    private func applyOverride() {
        weatherService.setDebugOverride(condition: selectedCondition, isNight: isNight)
    }
}
