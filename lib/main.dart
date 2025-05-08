import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:medalarmm/constants/app_constants.dart';
import 'package:medalarmm/providers/medication_provider.dart';
import 'package:medalarmm/providers/user_profile_provider.dart';
import 'package:medalarmm/screens/splash_screen.dart';
import 'package:medalarmm/services/database_service.dart';
import 'package:medalarmm/services/notification_service.dart';
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
      ],
      child: MaterialApp(
        title: 'MedAlarm',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            error: AppColors.error,
            background: AppColors.background,
            surface: AppColors.surface,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
            ),
          ),
          fontFamily: 'Poppins',
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );  }
}
