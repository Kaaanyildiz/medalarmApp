import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  static const String _themePreferenceKey = 'is_dark_mode';

  ThemeProvider() {
    _loadThemePreference();
  }

  /// Tema tercihini yükle
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themePreferenceKey) ?? false;
    
    // Cihaz temasını kullanmak için burada sistem temasını da kontrol edebiliriz
    // final brightness = SchedulerBinding.instance.window.platformBrightness;
    // final systemIsDark = brightness == Brightness.dark;
    
    _isDarkMode = isDark;
    notifyListeners();
  }

  /// Tema modunu değiştir
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _saveThemePreference();
    notifyListeners();
  }

  /// Tema tercihini kaydet
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, _isDarkMode);
  }

  /// Belirli bir tema modunu ayarla
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      _saveThemePreference();
      notifyListeners();
    }
  }
}
