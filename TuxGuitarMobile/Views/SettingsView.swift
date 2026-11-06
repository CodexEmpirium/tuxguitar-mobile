import SwiftUI

struct SettingsView: View {
    @AppStorage("showFretboard") private var showFretboard = true
    @AppStorage("darkNotation") private var darkNotation = false
    @AppStorage("hapticFeedback") private var hapticFeedback = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TuxGuitar Mobile")
                                .font(.headline)
                            Text("Native iPhone edition")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "guitars.fill")
                            .foregroundStyle(.orange)
                    }
                }

                Section("Editor") {
                    Toggle("Show fretboard", isOn: $showFretboard)
                    Toggle("Dark notation canvas", isOn: $darkNotation)
                    Toggle("Haptic feedback", isOn: $hapticFeedback)
                }

                Section("Compatibility") {
                    LabeledContent("Native format", value: ".tgsong")
                    LabeledContent("iOS target", value: "iOS 17+")
                    Link(destination: URL(string: "https://www.tuxguitar.app/")!) {
                        Label("Upstream TuxGuitar", systemImage: "arrow.up.right.square")
                    }
                }

                Section {
                    Text("The native editor model follows TuxGuitar's song, track, measure, beat, and note vocabulary. Guitar Pro and Power Tab parsing will be added at the Swift format-reader boundary.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
