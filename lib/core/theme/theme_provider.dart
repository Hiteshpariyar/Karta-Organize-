import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage key for persisting selected theme mode.
const String _kThemePreferenceKey = 'user_theme_mode_preference';

/// Manages active ThemeMode (System, Light, Dark) across the app,
/// with instant synchronous-feel local persistence via SharedPreferences.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  SharedPreferences? _prefs;

  @override
  ThemeMode build() {
    _initPersistence();
    return ThemeMode.system; // Default to system-following appearance
  }

  Future<void> _initPersistence() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedMode = _prefs?.getString(_kThemePreferenceKey);
      if (savedMode != null) {
        switch (savedMode) {
          case 'light':
            state = ThemeMode.light;
            break;
          case 'dark':
            state = ThemeMode.dark;
            break;
          case 'system':
          default:
            state = ThemeMode.system;
            break;
        }
      }
    } catch (_) {
      // Fallback gracefully if preferences unavailable
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      String modeStr;
      switch (mode) {
        case ThemeMode.light:
          modeStr = 'light';
          break;
        case ThemeMode.dark:
          modeStr = 'dark';
          break;
        case ThemeMode.system:
          modeStr = 'system';
          break;
      }
      await _prefs?.setString(_kThemePreferenceKey, modeStr);
    } catch (_) {}
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});
