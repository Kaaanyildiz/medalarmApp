import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  // Uygulama dilini saklayacak değişken
  Locale _locale = const Locale('tr', 'TR');
  
  // Tercihleri kaydetmek için kullanılacak anahtar
  static const String _localeKey = 'locale';
  
  // Getter
  Locale get locale => _locale;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  // Constructor'da async işlem yapmıyoruz
  LocaleProvider() {
    _loadSavedLocale();
  }
  
  // Kaydedilmiş dil tercihini yükle
  void _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_localeKey) ?? 'tr';
      final countryCode = languageCode == 'tr' ? 'TR' : 'US';
      _locale = Locale(languageCode, countryCode);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading locale: $e');
      _locale = const Locale('tr', 'TR');
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  // Dili değiştir ve tercihi kaydet
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, newLocale.languageCode);
      
      _locale = newLocale;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving locale preferences: $e');
    }
  }
  
  // Türkçe mi kontrol et
  bool get isTurkish => _locale.languageCode == 'tr';
  
  // İngilizce mi kontrol et 
  bool get isEnglish => _locale.languageCode == 'en';
  
  // Dili Türkçe'ye değiştir
  Future<void> setTurkish() async {
    await setLocale(const Locale('tr', 'TR'));
  }
  
  // Dili İngilizce'ye değiştir
  Future<void> setEnglish() async {
    await setLocale(const Locale('en', 'US'));
  }
}
