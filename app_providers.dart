import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Theme Provider ─────────────────────────────────────────────────
class ThemeProvider extends ChangeNotifier {
  static const String _key = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
    notifyListeners();
  }
}

// ── Locale Provider ────────────────────────────────────────────────
class LocaleProvider extends ChangeNotifier {
  static const String _key = 'locale';

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'sq': 'Shqip',
    'el': 'Ελληνικά',
  };

  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  String get languageName =>
      supportedLanguages[_locale.languageCode] ?? 'English';

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key) ?? 'en';
    _locale = Locale(saved);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) return;
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
    notifyListeners();
  }
}

// ── Biometric Provider ─────────────────────────────────────────────
class BiometricProvider extends ChangeNotifier {
  static const String _key = 'biometric_enabled';
  bool _biometricEnabled = false;

  bool get biometricEnabled => _biometricEnabled;

  BiometricProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> setBiometric(bool value) async {
    _biometricEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    notifyListeners();
  }
}
