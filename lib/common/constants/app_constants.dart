import 'package:flutter/material.dart';

/// Uygulama renkleri
class AppColors {
  /// Açık tema renkleri
  // Ana renkler
  static const primary = Color(0xFF3F8CFF);     // Daha açık, canlı bir mavi
  static const primaryLight = Color(0xFFD0E1FF); // Ana rengin açık tonu
  static const primaryDark = Color(0xFF0062D1);  // Ana rengin koyu tonu
  
  static const secondary = Color(0xFF4CD964);   // Yeşil - sağlık ve başarı hissi
  static const secondaryLight = Color(0xFFE6F9E9); // İkincil rengin açık tonu
  
  // Arka plan renkleri
  static const background = Color(0xFFF8FAFD);  // Çok açık mavi-gri
  static const surface = Colors.white;
  static const cardBackground = Color(0xFFFFFFFF);
  static const divider = Color(0xFFEEF2F6);     // Çok açık gri-mavi ayırıcı çizgi
  
  // Durum renkleri
  static const success = Color(0xFF4CD964);     // Yeşil - başarılı işlemler
  static const error = Color(0xFFFF3B30);       // Kırmızı - hatalar
  static const warning = Color(0xFFFFCC00);     // Sarı - uyarılar
  static const info = Color(0xFF5AC8FA);        // Açık mavi - bilgilendirme
  
  // Metin renkleri
  static const textPrimary = Color(0xFF1A2D50);   // Koyu lacivert
  static const textSecondary = Color(0xFF61708A); // Gri-mavi
  static const textLight = Color(0xFF9FA9BD);     // Açık gri-mavi
  static const textOnPrimary = Colors.white;      // Mavi üzerine beyaz
  
  // Gölgelendirme
  static const shadow = Color(0x1A000000);      // %10 siyah gölge
  
  /// Koyu tema renkleri
  // Ana renkler - koyu tema
  static const primaryDark_ = Color(0xFF4B93FF);     // Koyu temada daha parlak mavi
  static const primaryLightDark_ = Color(0xFF203354); // Koyu temada daha koyu mavi
  static const primaryDarkDark_ = Color(0xFF175FBE);  // Koyu temada koyu mavi
  
  static const secondaryDark_ = Color(0xFF50D16B);   // Koyu temada daha parlak yeşil
  static const secondaryLightDark_ = Color(0xFF1A3327); // Koyu temada koyu yeşil
  
  // Arka plan renkleri - koyu tema
  static const backgroundDark_ = Color(0xFF121212);  // Standart koyu tema arka planı
  static const surfaceDark_ = Color(0xFF1F1F1F);     // Biraz daha açık yüzey rengi
  static const cardBackgroundDark_ = Color(0xFF2C2C2C); // Kartlar için daha açık renk
  static const dividerDark_ = Color(0xFF323232);     // Koyu tema ayırıcı rengi
  
  // Metin renkleri - koyu tema
  static const textPrimaryDark_ = Color(0xFFF3F8FF);   // Beyaza yakın renk
  static const textSecondaryDark_ = Color(0xFFB3BFCF); // Açık gri-mavi
  static const textLightDark_ = Color(0xFF8A9AAF);     // Orta gri-mavi
  
  /// Her iki tema için ortak renkler
  // Durum renkleri koyu tema için aynı kalabilir veya az değiştirilebilir
  static const successDark_ = Color(0xFF4AD964);     // Daha parlak yeşil
  static const errorDark_ = Color(0xFFFF453A);       // Daha parlak kırmızı
  static const warningDark_ = Color(0xFFFFD60A);     // Daha parlak sarı
  static const infoDark_ = Color(0xFF64D2FF);        // Daha parlak mavi
}

/// Dinamik renk seçici - tema durumuna göre renk oluşturucu
class AppColorScheme {
  static bool isDarkMode = false;
  
  // Ana renkler
  static Color get primary => isDarkMode ? AppColors.primaryDark_ : AppColors.primary;
  static Color get primaryLight => isDarkMode ? AppColors.primaryLightDark_ : AppColors.primaryLight;
  static Color get primaryDark => isDarkMode ? AppColors.primaryDarkDark_ : AppColors.primaryDark;
  
  static Color get secondary => isDarkMode ? AppColors.secondaryDark_ : AppColors.secondary;
  static Color get secondaryLight => isDarkMode ? AppColors.secondaryLightDark_ : AppColors.secondaryLight;
  
  // Arka plan renkleri
  static Color get background => isDarkMode ? AppColors.backgroundDark_ : AppColors.background;
  static Color get surface => isDarkMode ? AppColors.surfaceDark_ : AppColors.surface;
  static Color get cardBackground => isDarkMode ? AppColors.cardBackgroundDark_ : AppColors.cardBackground;
  static Color get divider => isDarkMode ? AppColors.dividerDark_ : AppColors.divider;
  
  // Durum renkleri
  static Color get success => isDarkMode ? AppColors.successDark_ : AppColors.success;
  static Color get error => isDarkMode ? AppColors.errorDark_ : AppColors.error;
  static Color get warning => isDarkMode ? AppColors.warningDark_ : AppColors.warning;
  static Color get info => isDarkMode ? AppColors.infoDark_ : AppColors.info;
  
  // Metin renkleri
  static Color get textPrimary => isDarkMode ? AppColors.textPrimaryDark_ : AppColors.textPrimary;
  static Color get textSecondary => isDarkMode ? AppColors.textSecondaryDark_ : AppColors.textSecondary;
  static Color get textLight => isDarkMode ? AppColors.textLightDark_ : AppColors.textLight;
  static Color get textOnPrimary => AppColors.textOnPrimary; // Her iki tema için de beyaz
  
  // Gölgelendirme - koyu tema için daha koyu
  static Color get shadow => isDarkMode ? const Color(0x40000000) : AppColors.shadow;
}

/// Boyutlar ve aralıklar
class AppDimens {
  // Padding
  static const paddingXS = 4.0;
  static const paddingS = 8.0;
  static const paddingM = 16.0;
  static const paddingL = 24.0;
  static const paddingXL = 32.0;
  
  // Radius
  static const radiusS = 4.0;
  static const radiusM = 8.0;
  static const radiusL = 16.0;
  
  // Icon sizes
  static const iconSizeS = 16.0;
  static const iconSizeM = 24.0;
  static const iconSizeL = 32.0;
}

/// Metin stilleri
class AppTextStyles {
  // Font ailesi adını burada tanımlayın
  static const String _fontFamily = 'Poppins';
  
  // Başlıklar
  static const heading1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.3,
  );
  
  static const heading2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.35,
  );
  
  static const heading3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.4,
  );
  
  static const heading4 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // Gövde metinleri
  static const bodyText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const bodyTextBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const bodyTextSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static const bodyTextSmallBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  // Altyazılar ve ek bilgiler
  static const caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
    height: 1.4,
  );
  
  static const captionBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  static const subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  
  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  static const body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );
}

/// Uygulama sabitleri
class AppConstants {
  // Haftanın günleri
  static const List<String> weekDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  
  // Gün isimleri
  static const Map<String, String> weekDaysMap = {
    'monday': 'Pazartesi',
    'tuesday': 'Salı',
    'wednesday': 'Çarşamba',
    'thursday': 'Perşembe',
    'friday': 'Cuma',
    'saturday': 'Cumartesi',
    'sunday': 'Pazar',
  };
  
  // Uygulama adı
  static const appName = 'MedAlarm';
  
  // Uygulama sürümü
  static const appVersion = '1.0.0';
  
  // Bildirim kanalı ID'si
  static const notificationChannelId = 'medication_reminders';
  
  // Bildirim kanalı adı
  static const notificationChannelName = 'İlaç Hatırlatmaları';
  
  // Bildirim kanalı açıklaması
  static const notificationChannelDescription = 'İlaç hatırlatmaları için bildirim kanalı';
}