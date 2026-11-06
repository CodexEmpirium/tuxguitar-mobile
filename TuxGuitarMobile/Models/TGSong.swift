import Foundation

/// The portable subset of TuxGuitar's song graph used by the first iOS target.
///
/// The names intentionally follow the upstream model (`TGSong`, `TGTrack`,
/// `TGMeasure`, `TGBeat`, and `TGNote`) so a future format reader can map its
/// output without forcing the SwiftUI layer to change.
struct TGSong: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var artist: String
    var album: String
    var tempo: Int
    var keySignature: String
    var tracks: [TGTrack]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        artist: String = "",
        album: String = "",
        tempo: Int = 96,
        keySignature: String = "C",
        tracks: [TGTrack],
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.tempo = tempo
        self.keySignature = keySignature
        self.tracks = tracks
        self.createdAt = createdAt
    }

    var subtitle: String {
        let details = [artist, album].filter { !$0.isEmpty }
        return details.isEmpty ? "TuxGuitar Mobile" : details.joined(separator: " • ")
    }

    var measureCount: Int {
        tracks.map { $0.measures.count }.max() ?? 0
    }

    static func importedPlaceholder(fileName: String) -> TGSong {
        let title = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        return TGSong(
            title: title.isEmpty ? "Imported song" : title,
            artist: "Imported from TuxGuitar",
            tempo: 96,
            tracks: [
                TGTrack(
                    name: "Imported track",
                    instrument: "Guitar",
                    measures: [TGMeasure.demo(number: 1)]
                )
            ]
        )
    }
}

struct TGTrack: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var instrument: String
    var stringCount: Int
    var tuning: [Int]
    var measures: [TGMeasure]

    init(
        id: UUID = UUID(),
        name: String,
        instrument: String,
        stringCount: Int = 6,
        tuning: [Int] = [64, 59, 55, 50, 45, 40],
        measures: [TGMeasure]
    ) {
        self.id = id
        self.name = name
        self.instrument = instrument
        self.stringCount = stringCount
        self.tuning = tuning
        self.measures = measures
    }
}

struct TGMeasure: Identifiable, Codable, Hashable {
    var id: UUID
    var number: Int
    var timeSignature: String
    var beats: [TGBeat]

    init(
        id: UUID = UUID(),
        number: Int,
        timeSignature: String = "4/4",
        beats: [TGBeat]
    ) {
        self.id = id
        self.number = number
        self.timeSignature = timeSignature
        self.beats = beats
    }

    static func demo(number: Int) -> TGMeasure {
        TGMeasure(
            number: number,
            beats: (0..<4).map { beat in
                TGBeat(position: beat, notes: [TGNote(string: 1, fret: [0, 3, 5, 3][beat])])
            }
        )
    }
}

struct TGBeat: Identifiable, Codable, Hashable {
    var id: UUID
    var position: Int
    var duration: String
    var notes: [TGNote]

    init(
        id: UUID = UUID(),
        position: Int,
        duration: String = "quarter",
        notes: [TGNote]
    ) {
        self.id = id
        self.position = position
        self.duration = duration
        self.notes = notes
    }
}

struct TGNote: Identifiable, Codable, Hashable {
    var id: UUID
    /// String 1 is the high string, matching the familiar TuxGuitar display.
    var string: Int
    var fret: Int
    var technique: String?

    init(
        id: UUID = UUID(),
        string: Int,
        fret: Int,
        technique: String? = nil
    ) {
        self.id = id
        self.string = string
        self.fret = fret
        self.technique = technique
    }

    var midiPitch: Int {
        let openPitch = [64, 59, 55, 50, 45, 40]
        let base = openPitch.indices.contains(string - 1) ? openPitch[string - 1] : 40
        return base + fret
    }

    var pitchName: String {
        let names = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "G♯", "A", "B♭", "B"]
        let pitch = midiPitch
        return "\(names[pitch % 12])\(pitch / 12 - 1)"
    }
}

enum DemoSongFactory {
    static func makeBlackbird() -> TGSong {
        let patterns: [[(Int, Int, String?)]] = [
            [(2, 3, nil), (3, 2, nil), (4, 0, nil), (5, 0, nil)],
            [(2, 3, nil), (3, 2, nil), (4, 0, nil), (5, 3, nil)],
            [(1, 0, "hammer-on"), (2, 3, nil), (3, 2, nil), (4, 0, nil)],
            [(1, 3, nil), (2, 3, nil), (3, 2, nil), (4, 0, nil)],
            [(1, 0, nil), (2, 1, nil), (3, 0, nil), (4, 2, nil)],
            [(1, 3, nil), (2, 3, nil), (3, 2, nil), (4, 0, nil)],
            [(2, 1, nil), (3, 0, nil), (4, 2, nil), (5, 0, nil)],
            [(1, 0, nil), (2, 3, nil), (3, 2, nil), (4, 0, nil)]
        ]

        let measures = patterns.enumerated().map { index, pattern in
            TGMeasure(
                number: index + 1,
                beats: pattern.enumerated().map { beatIndex, chord in
                    TGBeat(
                        position: beatIndex,
                        notes: [TGNote(string: chord.0, fret: chord.1, technique: chord.2)]
                    )
                }
            )
        }

        let guitar = TGTrack(
            name: "Acoustic Guitar",
            instrument: "Steel-string acoustic",
            measures: measures
        )

        let bass = TGTrack(
            name: "Bass",
            instrument: "Finger bass",
            stringCount: 4,
            tuning: [43, 38, 33, 28],
            measures: measures.map { measure in
                TGMeasure(
                    number: measure.number,
                    beats: measure.beats.map { beat in
                        TGBeat(
                            position: beat.position,
                            notes: [TGNote(string: 1, fret: max(0, beat.position - 1))]
                        )
                    }
                )
            }
        )

        return TGSong(
            title: "Blackbird",
            artist: "Demo arrangement",
            album: "TuxGuitar Mobile",
            tempo: 92,
            keySignature: "G",
            tracks: [guitar, bass]
        )
    }
}
