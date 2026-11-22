import SwiftUI

@main
struct ClaudeIslandApp: App {
    @StateObject private var controller = IslandController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(controller)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var controller: IslandController
    @Environment(\.scenePhase) private var phase

    @AppStorage("address") private var address = ""
    @AppStorage("token") private var token = ""
    @AppStorage("enabled") private var enabled = false
    @AppStorage("useLocation") private var useLocation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Relay on your PC") {
                    TextField("192.168.1.50:8787", text: $address)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    SecureField("Token", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section {
                    Button(controller.running ? "Disconnect" : "Connect") {
                        if controller.running {
                            enabled = false
                            controller.stop()
                        } else {
                            enabled = true
                            controller.wantsLocation = useLocation
                            controller.start(address: address, token: token)
                        }
                    }
                    .disabled(address.trimmingCharacters(in: .whitespaces).isEmpty && !controller.running)

                    Text(controller.status)
                    if !controller.islandStatus.isEmpty {
                        Text(controller.islandStatus)
                            .foregroundStyle(.secondary)
                    }
                }

                if let s = controller.last {
                    Section("Right now") {
                        LabeledContent("State", value: s.state.capitalized)
                        LabeledContent("Project", value: s.project.isEmpty ? "-" : s.project)
                        LabeledContent("Doing", value: s.detail)
                        LabeledContent("Sessions", value: "\(s.sessionCount)")
                    }
                }

                Section {
                    Toggle("Extra keep-alive (location)", isOn: $useLocation)
                } footer: {
                    Text("Turn this on if the island stops updating when the app is in the background. iOS will ask for location access (choose While Using). Your location is never read or sent anywhere. It's only used to keep the app running.")
                }

                Section("Diagnostics") {
                    LabeledContent("Last update") {
                        if let d = controller.lastEventAt {
                            Text(d, style: .time)
                        } else {
                            Text("never")
                        }
                    }
                    LabeledContent("Updates received", value: "\(controller.eventCount)")
                    LabeledContent("...while in background", value: "\(controller.backgroundEventCount)")
                    LabeledContent("Audio keep-alive", value: controller.audioPlaying ? "playing" : "NOT playing")
                }

                Section {
                    Text("Leave this app open in the app switcher (don't swipe it away) and the island keeps updating while you use other apps. If the island disappears, open this app once to bring it back.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Claude Island")
        }
        .onAppear {
            if enabled && !controller.running {
                controller.wantsLocation = useLocation
                controller.start(address: address, token: token)
            }
        }
        .onChange(of: useLocation) { _, newValue in
            controller.setLocationKeepAlive(newValue)
        }
        .onChange(of: phase) { _, newPhase in
            controller.setBackground(newPhase == .background)
            if newPhase == .active {
                controller.refreshActivity()
                controller.refreshDiagnostics()
            }
        }
    }
}
