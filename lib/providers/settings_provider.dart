import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _settingsBox = 'settings';

class AppSettings {
  final bool darkMode;

  const AppSettings({this.darkMode = false});

  AppSettings copyWith({bool? darkMode}) =>
      AppSettings(darkMode: darkMode ?? this.darkMode);
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(_load());

  static AppSettings _load() {
    final box = Hive.box(_settingsBox);
    return AppSettings(
      darkMode: box.get('dark_mode', defaultValue: false) as bool,
    );
  }

  void setDarkMode(bool value) {
    Hive.box(_settingsBox).put('dark_mode', value);
    state = state.copyWith(darkMode: value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((_) => SettingsNotifier());
