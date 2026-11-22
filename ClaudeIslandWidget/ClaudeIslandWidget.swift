import ActivityKit
import SwiftUI
import WidgetKit

@main
struct ClaudeIslandBundle: WidgetBundle {
    var body: some Widget {
        ClaudeLiveActivity()
    }
}

// MARK: - Look and feel

enum Style {
    static let claudeOrange = Color(red: 0.85, green: 0.47, blue: 0.34)

    static func color(_ state: String) -> Color {
        switch state {
        case "working": return claudeOrange
        case "waiting": return .yellow
        case "done": return .green
        default: return .gray
        }
    }

    static func symbol(_ state: String) -> String {
        switch state {
        case "working": return "sparkles"
        case "waiting": return "exclamationmark.bubble.fill"
        case "done": return "checkmark.circle.fill"
        default: return "moon.zzz.fill"
        }
    }

    static func label(_ state: String) -> String {
        switch state {
        case "working": return "Working"
        case "waiting": return "Needs you"
        case "done": return "Done"
        default: return "Idle"
        }
    }

    static func shortLabel(_ state: String) -> String {
        switch state {
        case "waiting": return "Input"
        case "done": return "Done"
        default: return "Idle"
        }
    }
}

struct StatusIcon: View {
    let state: String

    var body: some View {
        Image(systemName: Style.symbol(state))
            .foregroundStyle(Style.color(state))
    }
}

/// Counts up from `since` while working, otherwise shows the state name.
struct ElapsedOrLabel: View {
    let content: ClaudeActivityAttributes.ContentState
    var compact: Bool = false

    var body: some View {
        if content.state == "working" {
            Text(content.since, style: .timer)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Style.color(content.state))
                .font(compact ? .caption2 : .subheadline)
                .frame(width: compact ? 40 : 56, alignment: .trailing)
        } else {
            Text(compact ? Style.shortLabel(content.state) : Style.label(content.state))
                .foregroundStyle(Style.color(content.state))
                .font(compact ? .caption2 : .subheadline)
        }
    }
}

// MARK: - Lock screen / banner

struct LockScreenView: View {
    let content: ClaudeActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            StatusIcon(state: content.state)
                .font(.title)
            VStack(alignment: .leading, spacing: 2) {
                Text(content.project)
                    .font(.headline)
                    .lineLimit(1)
                Text(content.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                ElapsedOrLabel(content: content)
                if content.sessionCount > 1 {
                    Text("\(content.sessionCount) sessions")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}

// MARK: - The Live Activity itself

struct ClaudeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClaudeActivityAttributes.self) { context in
            LockScreenView(content: context.state)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    StatusIcon(state: context.state.state)
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ElapsedOrLabel(content: context.state)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.project)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        Spacer()
                        if context.state.sessionCount > 1 {
                            Text("\(context.state.sessionCount) sessions")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } compactLeading: {
                StatusIcon(state: context.state.state)
            } compactTrailing: {
                ElapsedOrLabel(content: context.state, compact: true)
            } minimal: {
                StatusIcon(state: context.state.state)
            }
            .keylineTint(Style.color(context.state.state))
        }
    }
}
