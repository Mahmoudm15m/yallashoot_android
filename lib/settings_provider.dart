import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'themeMode';
  static const String _langKey = 'languageCode';
  static const String _timezoneKey = 'timeZoneOffset';
  static const String _fontScaleKey = 'fontScaleFactor';

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('ar');
  int _timeZoneOffset = 180;
  double _fontScaleFactor = 1.0;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  int get timeZoneOffset => _timeZoneOffset;
  double get fontScaleFactor => _fontScaleFactor;

  SettingsProvider();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // --- تحميل اللغة ---
    final String languageCodeToSet;
    final String? savedLangCode = prefs.getString(_langKey);
    if (savedLangCode != null) {
      languageCodeToSet = savedLangCode;
    } else {
      final String systemLangCode = ui.window.locale.languageCode;
      languageCodeToSet = (systemLangCode == 'ar') ? 'ar' : 'en';
    }
    _locale = Locale(languageCodeToSet);

    // --- تحميل المنطقة الزمنية ---
    final int? savedTimezone = prefs.getInt(_timezoneKey);
    if (savedTimezone != null) {
      _timeZoneOffset = savedTimezone;
    } else {
      final systemOffsetInMinutes = DateTime.now().timeZoneOffset.inMinutes;
      final roundedOffset = (systemOffsetInMinutes / 60).round() * 60;
      _timeZoneOffset = roundedOffset;
    }

    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.light.index;
    _themeMode = ThemeMode.values[themeIndex];

    _fontScaleFactor = prefs.getDouble(_fontScaleKey) ?? 1.0;

    _fontScaleFactor = _fontScaleFactor.clamp(0.2, 1.5);
  }

  Future<void> updateThemeMode(ThemeMode newThemeMode) async {
    if (_themeMode == newThemeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, newThemeMode.index);
  }

  Future<void> updateLanguage(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, newLocale.languageCode);
  }

  Future<void> updateTimeZoneOffset(int newOffset) async {
    if (_timeZoneOffset == newOffset) return;
    _timeZoneOffset = newOffset;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timezoneKey, newOffset);
  }

  Future<void> updateFontScaleFactor(double newScale) async {

    final clampedScale = newScale.clamp(0.2, 1.5);

    if (_fontScaleFactor == clampedScale) return;

    _fontScaleFactor = clampedScale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, clampedScale);
  }
}