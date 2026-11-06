import SwiftUI
import UniformTypeIdentifiers

struct TuxGuitarDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.tuxGuitarSong, .json, .data]
    }

    static var writableContentTypes: [UTType] {
        [.tuxGuitarSong]
    }

    var song: TGSong

    init(song: TGSong) {
        self.song = song
    }

    init(configuration: ReadConfiguration) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        song = try decoder.decode(TGSong.self, from: configuration.file.regularFileContents ?? Data())
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return FileWrapper(regularFileWithContents: try encoder.encode(song))
    }
}
