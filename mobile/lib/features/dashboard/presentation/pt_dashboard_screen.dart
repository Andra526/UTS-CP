import 'package:flutter/material.dart';

import '../../bookings/presentation/pt_session_management_screen.dart';
import '../../client_goals/presentation/pt_clients_tab.dart';
import '../../profile/presentation/pt_profile_screen.dart';
import '../../schedules/presentation/pt_schedule_screen.dart';
import 'pt_home_tab.dart';

/// Kerangka dashboard Personal Trainer dengan 5 tab.
class PtDashboardScreen extends StatefulWidget {
  const PtDashboardScreen({super.key});

  @override
  State<PtDashboardScreen> createState() => _PtDashboardScreenState();
}

class _PtDashboardScreenState extends State<PtDashboardScreen> {
  int _currentIndex = 0;

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      PtHomeTab(onNavigate: _goToTab),
      const PtClientsTab(),
      const PtSessionManagementScreen(),
      const PtScheduleScreen(),
      const PtProfileScreen(),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: _goToTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Klien',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center),
              label: 'Sesi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Jadwal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
