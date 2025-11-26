import 'package:flutter/material.dart';

class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
    this.enabled = true,
  });

  final bool isPlaying;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
      label: Text(isPlaying ? 'Pause' : 'Play'),
    );
  }
}

