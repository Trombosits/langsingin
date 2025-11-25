import 'package:flutter/material.dart';
import 'package:langsingin/main.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _laporanHarian;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLaporanHarian();
  }

  Future<void> _loadLaporanHarian() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await supabase
          .from('laporan_harian')
          .select()
          .eq('tanggal', today)
          .maybeSingle();

      setState(() {
        _laporanHarian = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLaporanHarian,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Halo! 👋',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(user?.email ?? 'User',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Laporan Hari Ini',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.restaurant,
                    title: 'Kalori Masuk',
                    value: '${_laporanHarian?['total_kalori_in'] ?? 0}',
                    unit: 'kcal',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.directions_run,
                    title: 'Kalori Keluar',
                    value: '${_laporanHarian?['total_kalori_out'] ?? 0}',
                    unit: 'kcal',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    icon: Icons.analytics,
                    title: 'Selisih Kalori',
                    value: '${_laporanHarian?['selisih_kalori'] ?? 0}',
                    unit: 'kcal',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  Text('Nutrisi Hari Ini',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildNutritionCard('Karbo', '${_laporanHarian?['total_karbo'] ?? 0}', 'g', Colors.amber)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildNutritionCard('Protein', '${_laporanHarian?['total_protein'] ?? 0}', 'g', Colors.red)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildNutritionCard('Lemak', '${_laporanHarian?['total_lemak'] ?? 0}', 'g', Colors.purple)),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value, required String unit, required Color color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text(unit, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(String label, String value, String unit, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}