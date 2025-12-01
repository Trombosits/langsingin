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

    final int kaloriMasuk = _laporanHarian?['total_kalori_in'] ?? 0;
    final int kaloriKeluar = _laporanHarian?['total_kalori_out'] ?? 0;
    final int kaloriTarget = 2600;
    final int sisaKalori = kaloriTarget - kaloriMasuk + kaloriKeluar;

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
                padding: const EdgeInsets.all(16),
                children: [
                  // Kalori Header
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monitor Kalori',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$kaloriMasuk',
                            style: const TextStyle(
                                fontSize: 48, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Sisa: $sisaKalori kkal',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: kaloriMasuk / kaloriTarget > 1
                                ? 1
                                : kaloriMasuk / kaloriTarget,
                            backgroundColor: Colors.grey[300],
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Kalori Masuk & Keluar
                  Row(
                    children: [
                      Expanded(
                        child: _buildKaloriCard(
                          icon: Icons.restaurant,
                          label: 'Kalori Masuk',
                          value: '$kaloriMasuk',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKaloriCard(
                          icon: Icons.directions_run,
                          label: 'Kalori Keluar',
                          value: '$kaloriKeluar',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Makronutrien
                  const Text(
                    'Makronutrien',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNutriCard('Protein',
                            '${_laporanHarian?['total_protein'] ?? 0}g', Colors.red),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNutriCard('Karbo',
                            '${_laporanHarian?['total_karbo'] ?? 0}g', Colors.amber),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNutriCard('Lemak',
                            '${_laporanHarian?['total_lemak'] ?? 0}g', Colors.purple),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKaloriCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('$value kkal',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildNutriCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}