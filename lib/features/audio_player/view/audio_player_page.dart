import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/audio_player_controller.dart';
import '../models/audio_track.dart';
import '../widgets/album_art.dart';
import '../widgets/seek_bar.dart';
import '../state/audio_player_state.dart';
import 'package:local_music_player/theme/app_theme.dart';
import 'package:local_music_player/theme/theme_controller.dart';

class AudioPlayerPage extends ConsumerStatefulWidget {
  const AudioPlayerPage({super.key});

  @override
  ConsumerState<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends ConsumerState<AudioPlayerPage> {
  ProviderSubscription<AudioPlayerState>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<AudioPlayerState>(
      audioPlayerControllerProvider,
      (previous, next) {
        final message = next.errorMessage;
        if (message != null && message != previous?.errorMessage) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
          ref.read(audioPlayerControllerProvider.notifier).clearError();
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(audioPlayerControllerProvider);
    final notifier = ref.read(audioPlayerControllerProvider.notifier);

    return WillPopScope(
      onWillPop: () async {
        // Option A behavior:
        // If a track is playing, go back to library instead of exiting app.
        if (state.track != null) {
          await notifier.clearTrackAndStop();
          return false; // don't pop route
        }
        return true; // no track -> normal back behavior
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        children: [
                          _Header(onPick: () => _pickTrack()),
                          const SizedBox(height: 24),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              child:
                                  state.track == null
                                      ? _LibraryPlaceholder(
                                        onPick: () => _pickTrack(),
                                        state: state,
                                        onPlayFromLibrary: notifier.playTrack,
                                        onRefreshLibrary:
                                            notifier.refreshLibrary,
                                      )
                                      : _PlayerContent(
                                state: state,
                                onToggle: notifier.togglePlayPause,
                                onSeek: notifier.seek,
                                onPickNew: () => _pickTrack(),
                                onBack: notifier.clearTrackAndStop,
                              )
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (state.isLoading)
                Container(
                  color: const Color(0x33000000),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTrack() async {
    final outcome =
        await ref
            .read(audioPlayerControllerProvider.notifier)
            .pickAndLoadTrack();
    if (!mounted) return;
    if (outcome == AudioPickOutcome.cancelled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No file selected')));
    }
  }
}

/// Simple search bar at the top of the homepage
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: "Search songs...",
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// HOME / LIBRARY VIEW
class _LibraryPlaceholder extends StatefulWidget {
  const _LibraryPlaceholder({
    required this.onPick,
    required this.state,
    required this.onPlayFromLibrary,
    required this.onRefreshLibrary,
  });

  final VoidCallback onPick;
  final AudioPlayerState state;
  final ValueChanged<AudioTrack> onPlayFromLibrary;
  final VoidCallback onRefreshLibrary;

  @override
  State<_LibraryPlaceholder> createState() => _LibraryPlaceholderState();
}

class _LibraryPlaceholderState extends State<_LibraryPlaceholder> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final allTracks = widget.state.recentTracks;
    final filteredTracks =
        _query.isEmpty
            ? allTracks
            : allTracks.where((track) {
              final q = _query.toLowerCase();
              return track.title.toLowerCase().contains(q) ||
                  track.artist.toLowerCase().contains(q);
            }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Bar
          _SearchBar(
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Quick Action Cards (Pick MP3, Refresh)
          _QuickActionRow(
            onPick: widget.onPick,
            onRefreshLibrary: widget.onRefreshLibrary,
          ),
          const SizedBox(height: 32),

          // Browse Section - Featured Albums (filtered)
          _BrowseSection(
            tracks: filteredTracks,
            onTap: widget.onPlayFromLibrary,
          ),
          const SizedBox(height: 32),

          // Recent Plays Section
          Row(
            children: [
              Text(
                'Recent Plays',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onRefreshLibrary,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh library',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recent Tracks List (filtered)
          if (widget.state.libraryLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (filteredTracks.isEmpty)
            _EmptyLibraryState(
              onRefresh: widget.onRefreshLibrary,
              onPick: widget.onPick,
              hasSearchQuery: _query.isNotEmpty,
            )
          else
            ...filteredTracks.map(
              (track) => _ModernLibraryTile(
                track: track,
                onTap: () => widget.onPlayFromLibrary(track),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({required this.onPick, required this.onRefreshLibrary});

  final VoidCallback onPick;
  final VoidCallback onRefreshLibrary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            label: 'Pick MP3',
            icon: Icons.library_music_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFC239B3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: onPick,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            label: 'Refresh',
            icon: Icons.refresh_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA751), Color(0xFFFFE259)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: onRefreshLibrary,
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseSection extends StatelessWidget {
  const _BrowseSection({required this.tracks, required this.onTap});

  final List<AudioTrack> tracks;
  final ValueChanged<AudioTrack> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayTracks = tracks.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Browse Albums',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (displayTracks.isEmpty)
          _EmptyBrowseState()
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayTracks.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final track = displayTracks[index];
                return _AlbumCard(track: track, onTap: () => onTap(track));
              },
            ),
          ),
      ],
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.track, required this.onTap});

  final AudioTrack track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient:
                      track.artwork == null
                          ? const LinearGradient(
                            colors: [Color(0xFFFF9A56), Color(0xFFFF6B95)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : null,
                ),
                child:
                    track.artwork != null
                        ? Image.memory(track.artwork!, fit: BoxFit.cover)
                        : const Icon(
                          Icons.music_note_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBrowseState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.album_outlined,
            size: 64,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text('No albums found', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Pick an MP3 file or refresh to scan your device',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ModernLibraryTile extends StatelessWidget {
  const _ModernLibraryTile({required this.track, required this.onTap});

  final AudioTrack track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Album Art
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient:
                        track.artwork == null
                            ? const LinearGradient(
                              colors: [Color(0xFFFF9A56), Color(0xFFFF6B95)],
                            )
                            : null,
                  ),
                  child:
                      track.artwork != null
                          ? Image.memory(track.artwork!, fit: BoxFit.cover)
                          : const Icon(
                            Icons.music_note_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                ),
              ),
              const SizedBox(width: 16),

              // Track Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artist,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Play Button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: onTap,
                  icon: const Icon(Icons.play_arrow_rounded),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState({
    required this.onRefresh,
    required this.onPick,
    this.hasSearchQuery = false,
  });

  final VoidCallback onRefresh;
  final VoidCallback onPick;
  final bool hasSearchQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = hasSearchQuery ? 'No matching songs' : 'No MP3 files found';
    final subtitle =
        hasSearchQuery
            ? 'Try a different search keyword'
            : 'Pick an MP3 file to start playing music';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9A56), Color(0xFFFF6B95)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.music_note_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Pick MP3'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Scan Device'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// PLAYER VIEW
class _PlayerContent extends ConsumerWidget {
  const _PlayerContent({
    required this.state,
    required this.onToggle,
    required this.onSeek,
    required this.onPickNew,
    required this.onBack,
  });

  final AudioPlayerState state;
  final VoidCallback onToggle;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onPickNew;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = state.track!;
    final theme = Theme.of(context);

    return _PlayerCard(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "NOW PLAYING",
            style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 3),
          ),

          Text(
            "My music list",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 20),

          // Album art
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
  colors: [
    Theme.of(context).colorScheme.surface.withOpacity(0.6),
    Theme.of(context).colorScheme.surface,
  ],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
),

            ),
            child: AlbumArt(
              artwork: track.artwork,
              borderRadius: 20,
            ),
          ),

          const SizedBox(height: 16),

          Text(
  track.title,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  textAlign: TextAlign.center,
  style: theme.textTheme.titleLarge?.copyWith(
    fontWeight: FontWeight.bold,
  ),
),


          Text(track.artist,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge),

          //const SizedBox(height: 20),

          //const _Waveform(),

          const SizedBox(height: 8),

          SeekBar(
            position: state.position,
            duration: state.duration,
            onChanged: onSeek,
            highlightColor: AppTheme.primary,
            showLabels: false,
          ),

          // Time row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(state.position)),
              Text(_formatDuration(state.duration)),
            ],
          ),

          const SizedBox(height: 20),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: state.position > Duration.zero
                    ? () => onSeek(Duration.zero)
                    : null,
              ),

              const SizedBox(width: 16),

              _PlayCircleButton(
                isPlaying: state.isPlaying,
                onPressed: onToggle,
              ),

              const SizedBox(width: 16),

              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: () {
                  ref
                      .read(audioPlayerControllerProvider.notifier)
                      .playNextFromRecent();
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          TextButton.icon(
            onPressed: onPickNew,
            icon: const Icon(Icons.library_music),
            label: const Text("Pick another MP3"),
          ),
        ],
      ),
    );
  }
}


String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.child,
    this.padding = const EdgeInsets.all(32),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 35,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PlayCircleButton extends StatelessWidget {
  const _PlayCircleButton({required this.isPlaying, required this.onPressed});

  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 88,
        height: 88,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x66FF7A18),
              blurRadius: 25,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 44,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform();

  @override
  Widget build(BuildContext context) {
    final bars = <double>[12, 22, 32, 18, 40, 28, 36, 20, 14, 26, 24, 30];
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children:
            bars
                .map(
                  (height) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      height: height,
                      width: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.secondary],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Local Music Player',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        const _ThemeToggleButton(),
      ],
    );
  }
}

class _ThemeToggleButton extends ConsumerWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final isLight = mode != ThemeMode.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => controller.setTheme(ThemeMode.light),
            icon: Icon(
              Icons.wb_sunny_outlined,
              color:
                  isLight
                      ? AppTheme.primary
                      : Theme.of(context).iconTheme.color,
            ),
          ),
          IconButton(
            onPressed: () => controller.setTheme(ThemeMode.dark),
            icon: Icon(
              Icons.dark_mode_outlined,
              color:
                  !isLight
                      ? AppTheme.secondary
                      : Theme.of(context).iconTheme.color,
            ),
          ),
        ],
      ),
    );
  }
}
