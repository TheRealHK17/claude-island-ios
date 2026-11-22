import ActivityKit
import Foundation
import SwiftUI

/// What the relay sends us (matches relay/server.js aggregate()).
struct RelayState: Decodable {
    let state: String
    let project: String
    let detail: String
    let since: Double          // milliseconds since 1970, from the PC's clock
    let sessionCount: Int
    let waitingCount: Int
    let workingCount: Int
}

extension RelayState {
    var contentState: ClaudeActivityAttributes.ContentState {
        let now = Date().timeIntervalSince1970
        return ClaudeActivityAttributes.ContentState(
            state: state,
            project: project.isEmpty ? "Claude Code" : project,
            detail: detail,
            // clamp so a slightly-fast PC clock can't put the timer in the future
            since: Date(timeIntervalSince1970: min(since / 1000.0, now)),
            sessionCount: sessionCount,
            waitingCount: waitingCount
        )
    }
}

@MainActor
final class IslandController: ObservableObject {
    @Published var status: String = "Not connected"
    @Published var islandStatus: String = ""
    @Published var last: RelayState?
    @Published var running = false

    // Diagnostics (shown in the app so we can see what happens in the background)
    @Published var lastEventAt: Date?
    @Published var eventCount = 0
    @Published var backgroundEventCount = 0
    @Published var audioPlaying = false
    private var inBackground = false

    private var task: Task<Void, Never>?
    private var activity: Activity<ClaudeActivityAttributes>?
    private let keepAlive = KeepAlive()
    private let locationKeepAlive = LocationKeepAlive()
    var wantsLocation = false

    // MARK: - Start / stop

    func start(address: String, token: String) {
        task?.cancel()
        guard let url = Self.eventsURL(from: address) else {
            status = "That address doesn't look right. Try 192.168.1.50:8787"
            return
        }
        running = true
        keepAlive.start()
        if wantsLocation { locationKeepAlive.start() }
        task = Task { [weak self] in
            await self?.run(url: url, token: token)
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        running = false
        keepAlive.stop()
        locationKeepAlive.stop()
        status = "Disconnected"
        endAllActivities()
    }

    /// Called when the app comes to the foreground. iOS only lets an app *start*
    /// a Live Activity while it's visible, so this revives the island if it was
    /// dismissed or hit iOS's ~8 hour limit.
    func refreshActivity() {
        if running, let s = last {
            present(s)
        }
    }

    func setLocationKeepAlive(_ on: Bool) {
        wantsLocation = on
        if running {
            if on {
                locationKeepAlive.start()
            } else {
                locationKeepAlive.stop()
            }
        }
    }

    func setBackground(_ value: Bool) {
        inBackground = value
    }

    func refreshDiagnostics() {
        audioPlaying = keepAlive.isPlaying
    }

    private func fail(_ message: String) {
        status = message
        running = false
        keepAlive.stop()
    }

    static func eventsURL(from raw: String) -> URL? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return nil }
        if !s.contains("://") { s = "http://" + s }
        guard var comps = URLComponents(string: s), comps.host != nil else { return nil }
        comps.path = "/events"
        return comps.url
    }

    // MARK: - Relay connection (Server-Sent Events)

    private func run(url: URL, token: String) async {
        var backoff: UInt64 = 1
        while !Task.isCancelled {
            do {
                status = "Connecting..."
                var request = URLRequest(url: url)
                request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                if !token.isEmpty {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }

                let config = URLSessionConfiguration.ephemeral
                config.timeoutIntervalForRequest = 45   // relay pings every 15s, so silence = dead link
                config.timeoutIntervalForResource = 60 * 60 * 24 * 7
                let session = URLSession(configuration: config)

                let (bytes, response) = try await session.bytes(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                if http.statusCode == 401 {
                    fail("Wrong token. Check it matches config.json on your PC.")
                    return
                }
                guard http.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }

                status = "Connected"
                backoff = 1

                for try await line in bytes.lines {
                    if Task.isCancelled { return }
                    guard line.hasPrefix("data:") else { continue }
                    let json = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                    if let data = json.data(using: .utf8),
                       let s = try? JSONDecoder().decode(RelayState.self, from: data) {
                        last = s
                        lastEventAt = Date()
                        eventCount += 1
                        if inBackground { backgroundEventCount += 1 }
                        audioPlaying = keepAlive.isPlaying
                        present(s)
                    }
                }
                throw URLError(.networkConnectionLost)
            } catch {
                if Task.isCancelled { return }
                status = "Reconnecting... (\(error.localizedDescription))"
            }
            try? await Task.sleep(nanoseconds: backoff * 1_000_000_000)
            backoff = min(backoff * 2, 15)
        }
    }

    // MARK: - Live Activity

    private func present(_ s: RelayState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            islandStatus = "Live Activities are off. Turn them on in Settings > Claude Island."
            return
        }
        let content = ActivityContent(state: s.contentState, staleDate: nil)

        if let a = activity, a.activityState == .active {
            islandStatus = "Island is live"
            Task { await a.update(content) }
            return
        }

        // pick up one that survived an app relaunch
        if let existing = Activity<ClaudeActivityAttributes>.activities.first(where: { $0.activityState == .active }) {
            activity = existing
            islandStatus = "Island is live"
            Task { await existing.update(content) }
            return
        }

        do {
            activity = try Activity<ClaudeActivityAttributes>.request(
                attributes: ClaudeActivityAttributes(name: "Claude Code"),
                content: content,
                pushType: nil
            )
            islandStatus = "Island is live"
        } catch {
            islandStatus = "Open this app to (re)start the island: \(error.localizedDescription)"
        }
    }

    private func endAllActivities() {
        activity = nil
        islandStatus = ""
        Task {
            for a in Activity<ClaudeActivityAttributes>.activities {
                await a.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
