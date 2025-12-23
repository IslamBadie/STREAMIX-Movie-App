import 'package:flutter/material.dart';
import 'package:movies/screens/browse_tab.dart';
import 'package:movies/screens/home_tab.dart';
import 'package:movies/screens/profile.dart';
import 'package:movies/screens/search_tab.dart';
import 'package:movies/services/localization_service.dart';

class MainScreen extends StatefulWidget {
  static const String routeName = "Home";

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeTab(),
    SearchTab(),
    BrowseTab(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _screens.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
                Theme.of(context).scaffoldBackgroundColor,
        items: [
          _buildNavItem(Icons.home, LocalizationService().t('home')),
          _buildNavItem(Icons.search, LocalizationService().t('search')),
          _buildNavItem(Icons.explore, LocalizationService().t('browse')),
          _buildNavItem(Icons.person, LocalizationService().t('profile')),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor:
            Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
    );
  }
}
