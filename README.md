# TuxGuitar Mobile

An iPhone-first SwiftUI port of the TuxGuitar experience, based on the upstream project in `../tuxguitar`.

This repository is a native iOS application shell and editor foundation. The upstream project is Java-based, so its desktop SWT UI and Android Java UI cannot be compiled into an iOS target. This port keeps the same user-facing vocabulary—songs, tracks, measures, beats, notes, tablature, tempo, and transport—and provides a native path for the remaining format and playback work.

## Open in Xcode

1. Open `TuxGuitarMobile.xcodeproj` on macOS with Xcode 15 or newer.
2. Select the `TuxGuitarMobile` scheme and an iPhone simulator or connected iPhone.
3. Build and run. The project targets iOS 17 and uses SwiftUI.

The app includes a bundled demo song, a touch-friendly tablature editor, a fretboard input surface, transport controls with a lightweight practice synth, song metadata editing, and file import/export for the native `.tgsong` JSON format.

## Upstream format porting

The sibling TuxGuitar source remains the reference implementation. The next integration boundary is:

- `common/TuxGuitar-lib` for the song model, graphics layout, and core services.
- `common/TuxGuitar-gtp`, `common/TuxGuitar-gpx`, and `common/TuxGuitar-ptb` for Guitar Pro and Power Tab readers.
- `common/TuxGuitar-midi` plus the Android Gervill implementation for playback behavior.

Until those Java modules are translated to Swift or exposed through a separately maintained native library, upstream Guitar Pro files are imported as a clearly labeled placeholder instead of being silently treated as successfully parsed content. The native format is intentionally small and Codable so the UI can be exercised on an iPhone today.

## Project layout

```text
TuxGuitarMobile/
  App/          SwiftUI app entry point and app-level state
  Models/       Codable mobile song model
  Services/     library persistence, file documents, and playback
  Views/        library, editor, tablature, fretboard, and settings UI
```

The repository retains its existing `LICENSE` and also includes `LICENSE.LGPL-2.1` for the directly derived TuxGuitar material. See `UPSTREAM_NOTICE.md` for the relationship to TuxGuitar and the upstream license source.
