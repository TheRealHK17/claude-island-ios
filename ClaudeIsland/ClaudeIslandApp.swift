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
                    Text("Leave this app open in the app switcher (don't swipe it away) and the island keeps updating while you use other apps. If the island disappears, open this app once to bring it back.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Claude Island")
        }
        .onAppear {
            if enabled && !controller.running {
                controller.start(address: address, token: token)
            }
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .active {
                controller.refreshActivity()
            }
        }
    }
}
