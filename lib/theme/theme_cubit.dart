import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<AppThemeState> {
  static const _kDark = 'app_dark_mode_v1';

  ThemeCubit() : super(const AppThemeState(mode: ThemeMode.system));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_kDark);
    if (isDark == null) {
      emit(const AppThemeState(mode: ThemeMode.system));
    } else {
      emit(AppThemeState(mode: isDark ? ThemeMode.dark : ThemeMode.light));
    }
  }

  Future<void> toggleDark(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDark, value);
    emit(AppThemeState(mode: value ? ThemeMode.dark : ThemeMode.light));
  }
}
