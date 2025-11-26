Local Music Player

A clean and modern Flutter-based local music player built as part of the internship assessment.
The app scans your device for MP3 files, displays metadata & album art, and provides a smooth, interactive audio playback experience.

<p align="center"> <img src="screenshot.png" width="260"> </p>
🚀 Features

🎵 Automatic music scan
Detects MP3 files from common directories (Music, Downloads, External Storage).

📁 Library + Browse UI
Modern cards, horizontal album strip, and recent tracks section.

🎧 Full-featured audio player

Play / pause

Seek bar with drag-to-seek

Live position & duration timers

Next/previous controls

Auto-reset on completion

🖼 Metadata & Album Art
Extracts ID3 info (title, artist, artwork). Shows fallback artwork when missing.

🌙 Light & Dark theme
Custom Material 3 theme with a toggle switch.

📂 Manual MP3 file picker
Useful for selecting files outside the library scan.

🧩 Clean state management
Built with Riverpod + feature-first folder structure.

📦 Tech Stack

Flutter 3.27 / Dart 3.7

Riverpod (state management)

just_audio (audio playback)

ID3 (metadata + album art)

file_picker (manual MP3 selection)

audio_session

permission_handler

path_provider

📱 Screenshots

Add 2–3 screenshots here for more impact.
