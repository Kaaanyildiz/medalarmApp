import 'package:flutter/material.dart';
import 'package:medalarmm/constants/app_constants.dart';
import 'package:medalarmm/screens/calendar_screen.dart';
import 'package:medalarmm/screens/medication_list_screen.dart';
import 'package:medalarmm/screens/profile_screen.dart';
import 'package:medalarmm/screens/reports_screen.dart';

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

  final List<String> _titles = [
    'İlaçlarım',
    'Takvim',
    'Raporlar',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'İlaçlarım',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Takvim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Raporlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}