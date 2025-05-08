import 'package:flutter/material.dart';

/// Uygulama renkleri
class AppColors {
  static const primary = Color(0xFF1976D2);
  static const secondary = Color(0xFF03A9F4);
  static const accent = Color(0xFF00BCD4);
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const error = Color(0xFFD32F2F);
  static const warning = Color(0xFFFFA000);
  static const success = Color(0xFF4CAF50);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const cardBackground = Color(0xFFFAFAFA);
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
  static const heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
    static const bodyText = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );
  
  static const bodyTextBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const bodyTextSmall = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  
  static const caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
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