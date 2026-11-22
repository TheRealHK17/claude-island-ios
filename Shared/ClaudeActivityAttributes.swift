import ActivityKit
import Foundation

/// Shared by the app and the widget extension.
struct ClaudeActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var state: String        // "working" | "waiting" | "done" | "idle"
        var project: String
        var detail: String
        var since: Date          // when the current state began (drives the timer)
        var sessionCount: Int
        var waitingCount: Int
    }

    var name: String
}
