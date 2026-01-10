import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences prefs;

  ThemeCubit(this.prefs) : super(ThemeMode.light) {
    loadThemeMode();
  }

  Future<void> loadThemeMode() async {
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await prefs.setBool('is_dark_mode', mode == ThemeMode.dark);
    emit(mode);
  }
}




















