import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:langsingin/Screens/navbar.dart';
import 'package:langsingin/Screens/login.dart';
import 'package:langsingin/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:langsingin/Screens/fetchTrenKalori.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final _userId = supabase.auth.currentUser!.id;

    final user = supabase.auth.currentUser;

    Widget _getBottomTitles(double value, TitleMeta meta) {
      const style = TextStyle(fontSize: 12);
      const days = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];

      final index = value.toInt();
      if (index < 0 || index >= days.length) {
        return const SizedBox.shrink();
      }

      return Text(days[index], style: style);
    }
    return Scaffold(
      
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.email ?? 'User',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'User ID: ${user?.id ?? '-'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          // const SizedBox(height: 24),
          // Container(
          //   height: 200,
          //   child: FutureBuilder(
          //     future: TrenKaloriRepository.fetchWeeklyCalories(userId: _userId!),
          //     builder: (context, snapshot) {
          //       if (snapshot.connectionState == ConnectionState.waiting) {
                //   return const Center(child: CircularProgressIndicator());
                // }

                // if (snapshot.hasError) {
                //   return Center(
                //     child: Text('Error: ${snapshot.error}'),
                //   );
                // }

                // if (!snapshot.hasData) {
                //   return const Center(
          //           child: Text('Tidak ada data kalori.'),
          //         );
          //       }

          //       final weeklyCalories = snapshot.data!;

          //       return BarChart(
          //         BarChartData(
          //           barGroups: List.generate(7, (index) {
          //             return BarChartGroupData(
          //               x: index,
          //               barRods: [
          //                 BarChartRodData(
          //                   fromY: 0,
          //                   toY: weeklyCalories[index],
          //                   width: 18,
          //                   borderRadius: BorderRadius.circular(4),
          //                 ),
          //               ],
          //             );
          //           }),
          //           titlesData: FlTitlesData(
          //             show: true,
          //             bottomTitles: AxisTitles(
          //               sideTitles: SideTitles(
          //                 showTitles: true,
          //                 reservedSize: 42,
          //                 getTitlesWidget: _getBottomTitles,
          //               ),
          //             ),
          //             leftTitles: const AxisTitles(
          //               sideTitles: SideTitles(showTitles: true),
          //             ),
          //             topTitles: const AxisTitles(
          //               sideTitles: SideTitles(showTitles: false),
          //             ),
          //             rightTitles: const AxisTitles(
          //               sideTitles: SideTitles(showTitles: false),
          //             ),
          //           ),
          //           gridData: FlGridData(show: false),
          //           borderData: FlBorderData(show: false),
          //         ),
          //         duration: const Duration(milliseconds: 150),
          //         curve: Curves.linear,
          //       );
          //     },
          //   ),
          // ), 
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Bantuan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon!')));
            },
          ),
          const Divider(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
