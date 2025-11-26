import 'package:flutter/material.dart';

class SeekBar extends StatelessWidget {
  const SeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onChanged,
    this.highlightColor,
    this.showLabels = true,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onChanged;
  final Color? highlightColor;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final max = duration.inMilliseconds.toDouble();
    final value = position.inMilliseconds.clamp(0, max).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: highlightColor ?? Theme.of(context).colorScheme.primary,
            thumbColor: highlightColor ?? Theme.of(context).colorScheme.primary,
          ),
          child: Slider(
            value: max == 0 ? 0 : value,
            max: max == 0 ? 1 : max,
            onChanged: (newValue) {
              if (max == 0) return;
              onChanged(Duration(milliseconds: newValue.toInt()));
            },
          ),
        ),
        if (showLabels)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(position),
                  style: Theme.of(context).textTheme.bodySmall),
              Text(_formatDuration(duration),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

