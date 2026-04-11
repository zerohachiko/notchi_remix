import SwiftUI

struct CollapsedActivityView: View {
    let event: SessionEvent

    private var statusIcon: String {
        switch event.status {
        case .running: return "●"
        case .success: return "✓"
        case .error: return "✗"
        }
    }

    private var statusColor: Color {
        switch event.status {
        case .running: return TerminalColors.amber
        case .success: return TerminalColors.green
        case .error: return TerminalColors.red
        }
    }

    private var toolDisplayName: String {
        event.tool ?? event.type
    }

    private var shortDescription: String? {
        guard let desc = event.description else { return nil }
        let trimmed = desc.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let lastSlash = trimmed.lastIndex(of: "/") {
            let fileName = String(trimmed[trimmed.index(after: lastSlash)...])
            if !fileName.isEmpty { return fileName }
        }
        return String(trimmed.prefix(30))
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(statusIcon)
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(statusColor)

            Text(toolDisplayName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(TerminalColors.primaryText)

            if let desc = shortDescription {
                Text(desc)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(TerminalColors.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }
}

struct CollapsedPermissionView: View {
    let question: PendingQuestion

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 9))
                .foregroundColor(TerminalColors.claudeOrange)

            Text(question.question)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(TerminalColors.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

struct CollapsedSummaryView: View {
    let message: AssistantMessage

    private var summaryText: String {
        let text = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first(where: { !$0.isEmpty }) ?? text
        return String(firstLine.prefix(40))
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 9))
                .foregroundColor(TerminalColors.green)

            Text(summaryText)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(TerminalColors.secondaryText)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}
