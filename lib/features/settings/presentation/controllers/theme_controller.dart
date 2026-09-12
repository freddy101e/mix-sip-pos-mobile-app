import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>(
      (ref) => ThemeController()..restore(),
    );

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);

  static const _key = 'theme_mode';
  static const _storage = FlutterSecureStorage();

  Future<void> restore() async {
    final saved = await _storage.read(key: _key);
    state = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(key: _key, value: mode.name);
  }

  Future<void> toggle(Brightness brightness) {
    return setMode(
      brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
