# Local Music Player

A simple Flutter assignment project that lets you pick any MP3 stored on the device and play it locally with album art, metadata, seek controls, and basic error handling.

## Features
- Scans device storage (Music/Downloads/external dirs) for local `.mp3` files and shows them in a browse-first home screen.
- Browse cards + “Top hits” list mirror the provided mockup while remaining fully interactive; tapping any tile starts playback instantly.
- Manual MP3 picker remains available for edge cases or to jump to a different folder.
- Displays album art (if embedded) or a friendly placeholder and surfaces title/artist fallbacks.
- Just Audio–powered playback with play/pause, seek bar, drag-to-seek, and live timers; playback resets on completion.
- Light/Dark Material 3 themes with an in-app toggle (default: light).
- Riverpod architecture keeps player, library scanning, and theme state isolated and testable.

## Getting Started
1. **Install dependencies**
   ```bash
   flutter pub get
   ```
2. **Run on a device/emulator**
   ```bash
   flutter run
   ```

> The app targets Android/iOS (and other desktop platforms where file access is available). Picking files or reading metadata is not supported on the web build.

## Project Structure
- `lib/app.dart` – Material 3 theme + app shell.
- `lib/features/audio_player/` – Feature module containing:
  - `controller/` – Riverpod `AudioPlayerController`.
  - `models/` – `AudioTrack` metadata model.
  - `state/` – immutable state holder.
  - `view/` – `AudioPlayerPage` screen.
  - `widgets/` – Reusable UI components.

## Libraries
- [`just_audio`](https://pub.dev/packages/just_audio) for playback.
- [`audio_session`](https://pub.dev/packages/audio_session) to configure platform audio focus.
- [`file_picker`](https://pub.dev/packages/file_picker) for ad-hoc song selection.
- [`id3`](https://pub.dev/packages/id3) to parse track metadata and album art.
- [`permission_handler`](https://pub.dev/packages/permission_handler) + [`path_provider`](https://pub.dev/packages/path_provider) for storage access.
- [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) + [`equatable`](https://pub.dev/packages/equatable) for predictable state.

## Known Limitations / Notes
- Album art only loads if the MP3 contains an ID3 APIC frame.
- Permissions for storage access follow whatever the `file_picker` plugin requires on the target OS (make sure to accept prompts on Android 13+).
- No background playback or notification controls.
- Tested with Flutter 3.27 / Dart 3.7 – earlier versions might not include the latest Material color roles.

## Assignment Notes
- Core requirements (pick MP3, show metadata, playback with seek + timers, play/pause/reset, errors) are implemented.
- Optional items covered: Riverpod state management, clean folder structure, extracted widgets, theming, and this README.
