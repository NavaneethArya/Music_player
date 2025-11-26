import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/audio_player/view/audio_player_page.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class LocalMusicApp extends ConsumerWidget {
  const LocalMusicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    return MaterialApp(
      title: 'Local Music Player',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      debugShowCheckedModeBanner: false,
      home: const AudioPlayerPage(),
    );
  }
}
