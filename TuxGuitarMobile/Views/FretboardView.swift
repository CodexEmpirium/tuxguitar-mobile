import SwiftUI

struct FretboardView: View {
    @Binding var song: TGSong
    let selectedTrackID: UUID
    let selectedMeasure: Int
    @Binding var selectedBeat: Int

    private let frets = Array(0...12)

    private var trackIndex: Int? {
        song.tracks.firstIndex(where: { $0.id == selectedTrackID })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label("Fretboard", systemImage: "guitars")
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
                Text("Tap a fret to add a note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        Text("")
                            .frame(width: 24)
                        ForEach(frets, id: \.self) { fret in
                            Text("\(fret)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 34)
                        }
                    }

                    ForEach(0..<min(selectedTrackStringCount, 6), id: \.self) { stringIndex in
                        HStack(spacing: 0) {
                            Text(["e", "B", "G", "D", "A", "E"][stringIndex])
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            ForEach(frets, id: \.self) { fret in
                                Button {
                                    addNote(string: stringIndex + 1, fret: fret)
                                } label: {
                                    Text("")
                                        .frame(width: 34, height: 22)
                                        .background(fret == 0 ? .orange.opacity(0.1) : .clear)
                                        .overlay(alignment: .top) {
                                            Rectangle()
                                                .fill(.secondary.opacity(0.28))
                                                .frame(height: 1)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 9)
        .padding(.bottom, 8)
        .background(.background)
    }

    private var selectedTrackStringCount: Int {
        guard let trackIndex else { return 6 }
        return song.tracks[trackIndex].stringCount
    }

    private func addNote(string: Int, fret: Int) {
        guard let trackIndex,
              song.tracks.indices.contains(trackIndex),
              song.tracks[trackIndex].measures.indices.contains(selectedMeasure) else { return }

        let beatIndex = min(selectedBeat, max(0, song.tracks[trackIndex].measures[selectedMeasure].beats.count - 1))
        guard song.tracks[trackIndex].measures[selectedMeasure].beats.indices.contains(beatIndex) else { return }
        song.tracks[trackIndex].measures[selectedMeasure].beats[beatIndex].notes.append(
            TGNote(string: string, fret: fret)
        )
        selectedBeat = beatIndex
    }
}
