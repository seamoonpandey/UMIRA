import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/preferences_models.dart';

class LocalPrefsNotifier extends StateNotifier<LocalPrefs> {
  LocalPrefsNotifier() : super(const LocalPrefs()) {
    _load();
  }

  static const _key = 'umira_local_prefs';

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw != null) {
      try {
        state = LocalPrefs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<void> update(LocalPrefs Function(LocalPrefs) f) async {
    state = f(state);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(state.toJson()));
  }
}

final localPrefsProvider =
    StateNotifierProvider<LocalPrefsNotifier, LocalPrefs>(
        (_) => LocalPrefsNotifier(),);
