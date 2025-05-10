import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/features/medications/providers/medication_provider.dart';
import 'package:medalarmm/features/onboarding/providers/theme_provider.dart';
import 'package:medalarmm/features/profile/providers/user_profile_provider.dart';
import 'package:medalarmm/features/medications/screens/add_medication_screen.dart';
import 'package:medalarmm/features/calendar/screens/calendar_screen.dart';
import 'package:medalarmm/features/medications/screens/inventory_screen.dart';
import 'package:medalarmm/features/medications/screens/medication_list_screen.dart';
import 'package:medalarmm/features/profile/screens/profile_screen.dart';
import 'package:medalarmm/features/reports/screens/reports_screen.dart';
import 'package:medalarmm/features/onboarding/screens/splash_screen.dart';
import 'package:medalarmm/core/services/database_service.dart';
import 'package:medalarmm/core/services/notification_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Yerelleştirme verilerini başlat
  await initializeDateFormatting('tr_TR', null);
  
  // Servislerin başlatılması
  final databaseService = DatabaseService();
  await databaseService.init();
  
  final notificationService = NotificationService();
  await notificationService.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Tema durumunu AppColorScheme'e aktar
          AppColorScheme.isDarkMode = themeProvider.isDarkMode;
            return MaterialApp(            title: 'MedAlarm',
            debugShowCheckedModeBanner: false,
            theme: _getThemeData(isDark: false),
            darkTheme: _getThemeData(isDark: true),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            // Rota tanımlamaları 
            routes: {
              '/medications/add': (context) => const AddMedicationScreen(),
              '/medications/list': (context) => const MedicationListScreen(),
              '/calendar': (context) => const CalendarScreen(),
              '/reports': (context) => const ReportsScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/inventory': (context) => const InventoryScreen(),
              // Detail ekranı için parametre gerekiyor, onNavigator.push ile kullanılacak
            },
          );
        },
      ),
    );
  }
    /// Tema oluştur (açık/koyu tema)
  ThemeData _getThemeData({required bool isDark}) {
    // Tema durumunu AppColorScheme'e aktar
    AppColorScheme.isDarkMode = isDark;
    
    // Renk şeması
    final colorScheme = ColorScheme.fromSeed(
      brightness: isDark ? Brightness.dark : Brightness.light,
      seedColor: isDark ? AppColors.primaryDark_ : AppColors.primary,
      primary: isDark ? AppColors.primaryDark_ : AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      secondary: isDark ? AppColors.secondaryDark_ : AppColors.secondary,
      error: isDark ? AppColors.errorDark_ : AppColors.error,
      background: isDark ? AppColors.backgroundDark_ : AppColors.background,
      surface: isDark ? AppColors.surfaceDark_ : AppColors.surface,
      onSurface: isDark ? AppColors.textPrimaryDark_ : AppColors.textPrimary,
    );
    
    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.backgroundDark_ : AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.surfaceDark_ : Colors.transparent,
        foregroundColor: isDark ? AppColors.textPrimaryDark_ : AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.primaryDark_ : AppColors.primary,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark_ : AppColors.textPrimary,
        ),
      ),
      cardTheme: CardTheme(
        color: isDark ? AppColors.cardBackgroundDark_ : AppColors.cardBackground,
        elevation: 4,
        margin: const EdgeInsets.symmetric(
          vertical: AppDimens.paddingS,
          horizontal: AppDimens.paddingXS,
        ),
        shadowColor: isDark ? Colors.black.withOpacity(0.3) : AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.primaryDark_ : AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingL,
            vertical: AppDimens.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.primaryDark_ : AppColors.primary,
          side: BorderSide(
            color: isDark ? AppColors.primaryDark_ : AppColors.primary, 
            width: 1.5
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingL,
            vertical: AppDimens.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.primaryDark_ : AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark_ : AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: BorderSide(
            color: isDark ? AppColors.dividerDark_ : AppColors.divider, 
            width: 1
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryDark_ : AppColors.primary, 
            width: 2
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          borderSide: BorderSide(
            color: isDark ? AppColors.errorDark_ : AppColors.error, 
            width: 1
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingM,
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.textLightDark_ : AppColors.textLight
        ),
        labelStyle: TextStyle(
          color: isDark ? AppColors.textSecondaryDark_ : AppColors.textSecondary
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark_ : AppColors.surface,
        selectedItemColor: isDark ? AppColors.primaryDark_ : AppColors.primary,
        unselectedItemColor: isDark ? AppColors.textLightDark_ : AppColors.textLight,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.dividerDark_ : AppColors.divider,
        thickness: 1,
        space: AppDimens.paddingM,
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      );
     } 
    }    
 


