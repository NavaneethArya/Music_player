import 'package:equatable/equatable.dart';
import '../models/audio_track.dart';

class AudioPlayerState extends Equatable {
  const AudioPlayerState({
    required this.track,
    required this.isLoading,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.errorMessage,
    required this.recentTracks,
    required this.libraryLoading,
  });

  factory AudioPlayerState.initial() => const AudioPlayerState(
        track: null,
        isLoading: false,
        isPlaying: false,
        position: Duration.zero,
        duration: Duration.zero,
        errorMessage: null,
        recentTracks: <AudioTrack>[],
        libraryLoading: false,
      );

  final AudioTrack? track;
  final bool isLoading;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String? errorMessage;
  final List<AudioTrack> recentTracks;
  final bool libraryLoading;

  AudioPlayerState copyWith({
    AudioTrack? track,
    bool clearTrack = false,
    bool? isLoading,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    bool resetError = false,
    List<AudioTrack>? recentTracks,
    bool? libraryLoading,
  }) {
    return AudioPlayerState(
      track: clearTrack ? null : (track ?? this.track),
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage:
          resetError ? null : (errorMessage ?? this.errorMessage),
      recentTracks: recentTracks ?? this.recentTracks,
      libraryLoading: libraryLoading ?? this.libraryLoading,
    );
  }

  @override
  List<Object?> get props => [
        track,
        isLoading,
        isPlaying,
        position,
        duration,
        errorMessage,
        recentTracks,
        libraryLoading,
      ];
}

