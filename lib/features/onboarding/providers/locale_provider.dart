import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  // Uygulama dilini saklayacak değişken
  Locale _locale = const Locale('tr', 'TR');
  
  // Tercihleri kaydetmek için kullanılacak anahtar
  static const String _localeKey = 'locale';
  
  // Getter
  Locale get locale => _locale;
  
  // Kurulum ve tercihi yükleme
  LocaleProvider() {
    _loadLocaleFromPrefs();
  }
  
  // SharedPreferences'tan dil tercihini yükler
  Future<void> _loadLocaleFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey) ?? 'tr';
    
    // Dil koduna göre ülke kodunu belirle
    String countryCode = languageCode == 'tr' ? 'TR' : 'US';
    
    _locale = Locale(languageCode, countryCode);
    notifyListeners();
  }
  
  // Dili değiştir ve tercihi kaydet
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    
    // Tercihi kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    
    notifyListeners();
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
