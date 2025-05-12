import 'package:flutter/material.dart';
import 'package:medalarmm/common/constants/app_constants.dart';
import 'package:medalarmm/common/l10n/app_localizations.dart';
import 'package:medalarmm/features/calendar/screens/calendar_screen.dart';
import 'package:medalarmm/features/medications/screens/medication_list_screen.dart';
import 'package:medalarmm/features/profile/screens/profile_screen.dart';
import 'package:medalarmm/features/reports/screens/reports_screen.dart';
import 'package:medalarmm/features/onboarding/providers/locale_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const MedicationListScreen(),
    const CalendarScreen(),
    const ReportsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    final List<String> _titles = [
      loc.translate('medications'),
      loc.translate('calendar'),
      loc.translate('reports'),
      loc.translate('profile'),
    ];

    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            backgroundColor: Colors.white,
            elevation: 8,
            selectedLabelStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTextStyles.caption,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.medication),
                label: _titles[0],
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_today),
                label: _titles[1],
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.bar_chart),
                label: _titles[2],
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: _titles[3],
              ),
            ],
          ),
        );
      },
    );
  }
}