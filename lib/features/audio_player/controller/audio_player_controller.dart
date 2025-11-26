import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:id3/id3.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/audio_track.dart';
import '../state/audio_player_state.dart';

enum AudioPickOutcome { picked, cancelled, failed }

final audioPlayerControllerProvider =
    StateNotifierProvider<AudioPlayerController, AudioPlayerState>(
      (ref) => AudioPlayerController(AudioPlayer()),
    );

class AudioPlayerController extends StateNotifier<AudioPlayerState> {
  AudioPlayerController(this._player)
    : _subscriptions = [],
      super(AudioPlayerState.initial()) {
    _initialize();
  }

  final AudioPlayer _player;
  final List<StreamSubscription<dynamic>> _subscriptions;

  Future<void> _initialize() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    unawaited(_loadRecentTracks());

    _subscriptions.add(
      _player.positionStream.listen(
        (position) => state = state.copyWith(position: position),
      ),
    );

    _subscriptions.add(
      _player.durationStream.listen((duration) {
        if (duration != null) {
          state = state.copyWith(duration: duration);
        }
      }),
    );

    _subscriptions.add(
      _player.playerStateStream.listen((playerState) {
        final processingState = playerState.processingState;
        if (processingState == ProcessingState.completed) {
          _player.seek(Duration.zero);
          _player.pause();
          state = state.copyWith(isPlaying: false, position: Duration.zero);
        } else {
          state = state.copyWith(isPlaying: playerState.playing);
        }
      }),
    );
  }

  Future<void> clearTrackAndStop() async {
  try {
    await _player.stop();
  } catch (_) {}

  state = state.copyWith(
    clearTrack: true,
    isPlaying: false,
    position: Duration.zero,
  );
}


  Future<AudioPickOutcome> pickAndLoadTrack() async {
    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3'],
        withData: false,
      );

      if (selection == null || selection.files.single.path == null) {
        return AudioPickOutcome.cancelled;
      }

      final filePath = selection.files.single.path!;

      state = state.copyWith(isLoading: true, resetError: true);
      await _player.stop();
      await _player.setFilePath(filePath);

      final track = await _extractTrackMetadata(filePath);
      final resolvedDuration = _player.duration ?? Duration.zero;

      state = state.copyWith(
        track: track,
        duration: resolvedDuration,
        position: Duration.zero,
        isLoading: false,
        isPlaying: false,
      );

      return AudioPickOutcome.picked;
    } catch (e, st) {
      debugPrint('Failed to load track: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not play this file',
      );
      return AudioPickOutcome.failed;
    }
  }

  Future<void> playNextFromRecent() async {
  try {
    final current = state.track;
    if (current == null) return;

    final tracks = state.recentTracks;
    final index = tracks.indexWhere((t) => t.path == current.path);

    if (index == -1 || index == tracks.length - 1) {
      return; // no next song
    }

    final nextTrack = tracks[index + 1];
    await playTrack(nextTrack);
    await _player.play();
  } catch (_) {}
}


  Future<AudioTrack> _extractTrackMetadata(String filePath) async {
    final fileName = p.basenameWithoutExtension(filePath);
    String title = fileName;
    String artist = 'Unknown Artist';
    Uint8List? artworkBytes;

    try {
      final bytes = await File(filePath).readAsBytes();
      final mp3instance = MP3Instance(bytes);
      if (mp3instance.parseTagsSync()) {
        final tags = mp3instance.getMetaTags();
        final maybeTitle = tags?['Title'] as String?;
        final maybeArtist = tags?['Artist'] as String?;
        if (_isNotBlank(maybeTitle)) {
          title = maybeTitle!.trim();
        }
        if (_isNotBlank(maybeArtist)) {
          artist = maybeArtist!.trim();
        }

        final artFrame = tags?['APIC'];
        if (artFrame is Map<String, dynamic>) {
          final base64Art = artFrame['base64'] as String?;
          if (_isNotBlank(base64Art)) {
            artworkBytes = base64Decode(base64Art!);
          }
        }
      }
    } catch (e, st) {
      debugPrint('Metadata parse failed: $e\n$st');
    }

    return AudioTrack(
      path: filePath,
      title: title,
      artist: artist,
      artwork: artworkBytes,
    );
  }

  Future<void> togglePlayPause() async {
    if (state.track == null || state.isLoading) return;
    if (_player.playing) {
      await _player.pause();
      state = state.copyWith(isPlaying: false);
    } else {
      await _player.play();
      state = state.copyWith(isPlaying: true);
    }
  }

  Future<void> seek(Duration position) async {
    if (state.track == null) return;
    await _player.seek(position);
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(resetError: true);
    }
  }

  Future<void> refreshLibrary() => _loadRecentTracks();

  Future<void> playTrack(AudioTrack track) async {
    try {
      state = state.copyWith(isLoading: true, resetError: true);
      await _player.stop();
      await _player.setFilePath(track.path);
      state = state.copyWith(
        track: track,
        duration: _player.duration ?? Duration.zero,
        position: Duration.zero,
        isLoading: false,
        isPlaying: false,
      );
    } catch (e, st) {
      debugPrint('Failed to start track from library: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to open ${track.title}',
      );
    }
  }

  Future<void> _loadRecentTracks() async {
    try {
      state = state.copyWith(libraryLoading: true);
      final granted = await _ensureStoragePermission();
      if (!granted) {
        state = state.copyWith(
          libraryLoading: false,
          errorMessage: 'Storage permission denied',
        );
        return;
      }

      final candidates = await _candidateDirectories();
      final files = <FileSystemEntity>[];
      for (final dir in candidates) {
        if (!await dir.exists()) continue;
        try {
          files.addAll(
            dir
                .listSync(recursive: false)
                .where(
                  (entity) =>
                      entity is File &&
                      entity.path.toLowerCase().endsWith('.mp3'),
                ),
          );
        } catch (e) {
          debugPrint('Skipping directory ${dir.path}: $e');
        }
      }

      files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );
      final tracks = <AudioTrack>[];
      for (final file in files.take(15)) {
        final track = await _extractTrackMetadata(file.path);
        tracks.add(track);
      }

      state = state.copyWith(
        libraryLoading: false,
        recentTracks: tracks,
        resetError: true,
      );
    } catch (e, st) {
      debugPrint('Failed to load library: $e\n$st');
      state = state.copyWith(
        libraryLoading: false,
        errorMessage: 'Could not load local songs',
      );
    }
  }

  Future<bool> _ensureStoragePermission() async {
    final permissions = [
      Permission.audio,
      Permission.storage,
      Permission.mediaLibrary,
    ];
    for (final perm in permissions) {
      final status = await perm.request();
      if (status.isGranted) {
        return true;
      }
    }
    return false;
  }

  Future<List<Directory>> _candidateDirectories() async {
    final dirs = <Directory>[];
    try {
      final musicDir = Directory('/storage/emulated/0/Music');
      dirs.add(musicDir);
    } catch (_) {}

    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      dirs.add(downloadDir);
    } catch (_) {}

    final appDoc = await getApplicationDocumentsDirectory();
    dirs.add(appDoc);

    final externalDirs = await getExternalStorageDirectories();
    if (externalDirs != null) {
      dirs.addAll(externalDirs);
    }

    return dirs;
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}

bool _isNotBlank(String? value) => value != null && value.trim().isNotEmpty;
