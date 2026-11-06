import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "music.note.list")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "slider.horizontal.3")
                }
        }
    }
}

struct LibraryView: View {
    @EnvironmentObject private var library: SongLibrary
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var exportDocument = TuxGuitarDocument(song: DemoSongFactory.makeBlackbird())
    @State private var exportFileName = "TuxGuitar Song"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LibraryHeader()
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 10, trailing: 16))
                        .listRowBackground(Color.clear)
                }

                Section {
                    ForEach(library.songs) { song in
                        NavigationLink {
                            SongEditorView(song: library.binding(for: song.id))
                        } label: {
                            SongRow(song: song)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                library.remove(song)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                beginExport(song)
                            } label: {
                                Label("Export song", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                } header: {
                    Text("Songs")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("My songs")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isImporting = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .accessibilityLabel("Import song")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        library.addBlankSong()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New song")
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.tuxGuitarSong, .json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    library.importSong(from: url)
                }
            }
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .tuxGuitarSong,
                defaultFilename: exportFileName
            ) { _ in }
            .alert(
                "Import",
                isPresented: Binding(
                    get: { library.lastImportNotice != nil },
                    set: { if !$0 { library.lastImportNotice = nil } }
                )
            ) {
                Button("Done", role: .cancel) { library.lastImportNotice = nil }
            } message: {
                Text(library.lastImportNotice ?? "")
            }
        }
    }

    private func beginExport(_ song: TGSong) {
        exportDocument = TuxGuitarDocument(song: song)
        exportFileName = song.title.isEmpty ? "TuxGuitar Song" : song.title
        isExporting = true
    }
}

private struct LibraryHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.orange.gradient)
                    Image(systemName: "guitars")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 62, height: 62)

                VStack(alignment: .leading, spacing: 2) {
                    Text("TUXGUITAR")
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .tracking(1.2)
                    Text("Play. Practice. Create.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Your tabs, ready for the next riff.")
                .font(.headline)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.11), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct SongRow: View {
    let song: TGSong

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "music.quarternote.3")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.orange)
                .frame(width: 42, height: 42)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(song.title.isEmpty ? "Untitled song" : song.title)
                    .font(.headline)
                Text(song.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("\(song.tracks.count) track\(song.tracks.count == 1 ? "" : "s") • \(song.measureCount) measures • \(song.tempo) BPM")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }
}
