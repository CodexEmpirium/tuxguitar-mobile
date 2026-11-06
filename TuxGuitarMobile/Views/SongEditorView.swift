import SwiftUI

struct SongEditorView: View {
    @Binding var song: TGSong
    @StateObject private var playback = PlaybackController()
    @State private var selectedTrackID: UUID
    @State private var selectedMeasure = 0
    @State private var selectedBeat = 0
    @State private var showingDetails = false
    @AppStorage("showFretboard") private var showFretboard = true
    @AppStorage("darkNotation") private var darkNotation = false

    init(song: Binding<TGSong>) {
        _song = song
        _selectedTrackID = State(initialValue: song.wrappedValue.tracks.first?.id ?? UUID())
    }

    private var selectedTrack: TGTrack {
        song.tracks.first(where: { $0.id == selectedTrackID }) ?? song.tracks.first ?? TGTrack(
            name: "Guitar",
            instrument: "Guitar",
            measures: [TGMeasure.demo(number: 1)]
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            editorHeader
            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if selectedTrack.measures.isEmpty {
                        ContentUnavailableView("No measures", systemImage: "music.note", description: Text("Add a measure to start writing."))
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(Array(selectedTrack.measures.enumerated()), id: \.element.id) { index, measure in
                            TablatureMeasureView(
                                measure: measure,
                                stringCount: selectedTrack.stringCount,
                                isActive: index == selectedMeasure,
                                darkCanvas: darkNotation
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedMeasure = index
                                selectedBeat = min(selectedBeat, max(0, measure.beats.count - 1))
                                playback.jump(to: index)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
            .background(Color(uiColor: .secondarySystemBackground))

            if showFretboard {
                FretboardView(
                    song: $song,
                    selectedTrackID: selectedTrackID,
                    selectedMeasure: selectedMeasure,
                    selectedBeat: $selectedBeat
                )
                .frame(height: 188)
                .transition(.move(edge: .bottom))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TransportBar(song: song, track: selectedTrack, playback: playback)
        }
        .navigationTitle(song.title.isEmpty ? "Untitled" : song.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    ForEach(song.tracks) { track in
                        Button {
                            selectedTrackID = track.id
                            selectedMeasure = min(selectedMeasure, max(0, track.measures.count - 1))
                            playback.stop()
                        } label: {
                            if track.id == selectedTrackID {
                                Label(track.name, systemImage: "checkmark")
                            } else {
                                Text(track.name)
                            }
                        }
                    }
                } label: {
                    Label(selectedTrack.name, systemImage: "music.note")
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel("Choose track")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingDetails = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("Song details")
            }
        }
        .sheet(isPresented: $showingDetails) {
            SongDetailsView(song: $song)
                .presentationDetents([.medium])
        }
        .onDisappear {
            playback.stop()
        }
    }

    private var editorHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(song.artist.isEmpty ? "Untitled arrangement" : song.artist)
                    .font(.subheadline.weight(.semibold))
                Text("\(selectedTrack.instrument) • \(song.keySignature) • \(song.tempo) BPM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("M\(min(selectedMeasure + 1, max(1, selectedTrack.measures.count)))")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.orange)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(.orange.opacity(0.12), in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.background)
    }
}

private struct TablatureMeasureView: View {
    let measure: TGMeasure
    let stringCount: Int
    let isActive: Bool
    let darkCanvas: Bool

    private var canvasWidth: CGFloat {
        max(350, CGFloat(measure.beats.count * 74 + 44))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text("MEASURE \(measure.number)")
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(isActive ? .orange : .secondary)
                Text(measure.timeSignature)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 4) {
                    VStack(spacing: 0) {
                        ForEach(0..<min(stringCount, 6), id: \.self) { index in
                            Text(["e", "B", "G", "D", "A", "E"][index])
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                                .frame(width: 20, height: 13)
                        }
                    }
                    .padding(.top, 32)

                    Canvas { context, size in
                        var staff = Path()
                        for stringIndex in 0..<min(stringCount, 6) {
                            let y = 32 + CGFloat(stringIndex) * 13
                            staff.move(to: CGPoint(x: 0, y: y))
                            staff.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        context.stroke(
                            staff,
                            with: .color(darkCanvas ? .white.opacity(0.25) : .primary.opacity(0.18)),
                            lineWidth: 1
                        )

                        let beatWidth = (size.width - 32) / CGFloat(max(measure.beats.count, 1))
                        for (beatIndex, beat) in measure.beats.enumerated() {
                            let x = 16 + beatWidth * (CGFloat(beatIndex) + 0.5)
                            if beatIndex == 0 {
                                var bar = Path()
                                bar.move(to: CGPoint(x: 2, y: 23))
                                bar.addLine(to: CGPoint(x: 2, y: 104))
                                context.stroke(bar, with: .color(darkCanvas ? .white.opacity(0.55) : .primary.opacity(0.6)), lineWidth: 2)
                            }
                            for note in beat.notes {
                                let y = 32 + CGFloat(max(0, min(note.string - 1, 5))) * 13
                                context.draw(
                                    Text("\(note.fret)")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundStyle(darkCanvas ? Color.white : Color.primary),
                                    at: CGPoint(x: x, y: y)
                                )
                            }
                        }

                        var endBar = Path()
                        endBar.move(to: CGPoint(x: size.width - 2, y: 23))
                        endBar.addLine(to: CGPoint(x: size.width - 2, y: 104))
                        context.stroke(endBar, with: .color(darkCanvas ? .white.opacity(0.55) : .primary.opacity(0.6)), lineWidth: 2)
                    }
                    .frame(width: canvasWidth, height: 118)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
            }
            .background(darkCanvas ? Color.black.opacity(0.86) : Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isActive ? .orange.opacity(0.7) : .clear, lineWidth: 2)
            }
        }
    }
}

private struct TransportBar: View {
    let song: TGSong
    let track: TGTrack
    @ObservedObject var playback: PlaybackController

    var body: some View {
        HStack(spacing: 14) {
            Button {
                playback.toggle(song: song, track: track)
            } label: {
                Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3.weight(.bold))
                    .frame(width: 44, height: 44)
                    .background(.orange, in: Circle())
                    .foregroundStyle(.white)
            }
            .accessibilityLabel(playback.isPlaying ? "Pause" : "Play")

            VStack(alignment: .leading, spacing: 2) {
                Text(playback.isPlaying ? "Playing measure \(playback.activeMeasure + 1)" : "Ready to play")
                    .font(.subheadline.weight(.semibold))
                Text("\(song.tempo) BPM • Practice synth")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "metronome")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }
}

private struct SongDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var song: TGSong

    var body: some View {
        NavigationStack {
            Form {
                Section("Song") {
                    TextField("Title", text: $song.title)
                    TextField("Artist", text: $song.artist)
                    TextField("Album", text: $song.album)
                }

                Section("Composition") {
                    Stepper(value: $song.tempo, in: 40...240) {
                        LabeledContent("Tempo", value: "\(song.tempo) BPM")
                    }
                    TextField("Key signature", text: $song.keySignature)
                }
            }
            .navigationTitle("Song details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
