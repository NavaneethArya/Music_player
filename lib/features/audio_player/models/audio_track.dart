import 'dart:typed_data';

class AudioTrack {
  const AudioTrack({
    required this.path,
    required this.title,
    required this.artist,
    this.artwork,
  });

  final String path;
  final String title;
  final String artist;
  final Uint8List? artwork;
}

