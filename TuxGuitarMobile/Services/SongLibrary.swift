import Foundation
import Combine
import SwiftUI

@MainActor
final class SongLibrary: ObservableObject {
    @Published private(set) var songs: [TGSong]
    @Published var lastImportNotice: String?

    private let storageURL: URL

    init() {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageURL = applicationSupport.appendingPathComponent("songs.json")
        lastImportNotice = nil

        if let data = try? Data(contentsOf: storageURL),
           let decoded = try? Self.decoder.decode([TGSong].self, from: data),
           !decoded.isEmpty {
            songs = decoded
        } else {
            songs = [DemoSongFactory.makeBlackbird()]
        }
    }

    func binding(for id: UUID) -> Binding<TGSong> {
        Binding(
            get: {
                self.songs.first(where: { $0.id == id }) ?? DemoSongFactory.makeBlackbird()
            },
            set: { self.update($0) }
        )
    }

    func addBlankSong() {
        let song = TGSong(
            title: "New song",
            artist: "",
            tempo: 100,
            tracks: [
                TGTrack(name: "Guitar", instrument: "Steel-string acoustic", measures: [TGMeasure.demo(number: 1)])
            ]
        )
        songs.insert(song, at: 0)
        persist()
    }

    func update(_ song: TGSong) {
        guard let index = songs.firstIndex(where: { $0.id == song.id }) else { return }
        songs[index] = song
        persist()
    }

    func remove(_ song: TGSong) {
        songs.removeAll { $0.id == song.id }
        if songs.isEmpty {
            songs = [DemoSongFactory.makeBlackbird()]
        }
        persist()
    }

    func importSong(from url: URL) {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess { url.stopAccessingSecurityScopedResource() }
        }

        guard let data = try? Data(contentsOf: url) else {
            lastImportNotice = "TuxGuitar Mobile could not read that file."
            return
        }

        if let song = try? Self.decoder.decode(TGSong.self, from: data) {
            songs.insert(song, at: 0)
            lastImportNotice = "Imported \(song.title)."
        } else {
            let song = TGSong.importedPlaceholder(fileName: url.lastPathComponent)
            songs.insert(song, at: 0)
            lastImportNotice = "\(url.pathExtension.uppercased()) was added as a placeholder. The native parser port is the next integration step."
        }
        persist()
    }

    private func persist() {
        do {
            try FileManager.default.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Self.encoder.encode(songs).write(to: storageURL, options: .atomic)
        } catch {
            // Persistence is a convenience; the editor remains usable if the
            // simulator or device temporarily denies the application folder.
        }
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
