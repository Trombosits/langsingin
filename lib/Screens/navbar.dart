import 'package:flutter/material.dart';
import 'package:langsingin/Screens/dashboard.dart';
import 'package:langsingin/Screens/inputMenu.dart';
import 'package:langsingin/Screens/profile.dart';
import 'package:langsingin/Utility/performance.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  /* builder & halaman (non-nullable) */
  final List<Widget Function()> _pageBuilders = [
    () => const DashboardPage(),
    () => const FoodLogPage(),
    () => const ProfilePage(),
  ];

  final List<Widget> _pages = List<Widget>.filled(3, const SizedBox.shrink());

  @override
  void initState() {
    super.initState();
    _buildTab(0); // load tab pertama
  }

  /* helper: build + ukur performa */
  void _buildTab(int index) {
    final perf = Performance('Navbar tab-$index');
    setState(() => _selectedIndex = index);

    /* build halaman jika masih placeholder */
    if (_pages[index] is SizedBox) {
      _pages[index] = _pageBuilders[index]();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => perf.finish());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages, 
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _buildTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Diary'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}