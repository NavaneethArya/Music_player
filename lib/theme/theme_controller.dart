import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>(
  (ref) => ThemeController(),
);

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.light);

  void setTheme(ThemeMode mode) {
    if (mode == state) return;
    state = mode;
  }

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

extension ThemeDataX on ThemeMode {
  ThemeData toThemeData() {
    if (this == ThemeMode.dark) {
      return AppTheme.dark();
    }
    return AppTheme.light();
  }
}

