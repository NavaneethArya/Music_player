import 'dart:typed_data';

import 'package:flutter/material.dart';

class AlbumArt extends StatelessWidget {
  const AlbumArt({
    super.key,
    this.artwork,
    this.borderRadius = 16,
  });

  final Uint8List? artwork;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: artwork != null
              ? Image.memory(
                  artwork!,
                  fit: BoxFit.cover,
                )
              : Icon(
                  Icons.music_note_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }
}

