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
      if (userId == null) {
  setState(() => _isLoading = false);
  return;
}

      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await supabase
          .from('laporan_harian')
          .select()
          .eq('id_user', userId)
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

    final double kaloriMasuk = double.tryParse('${_laporanHarian?['total_kalori_in'] ?? 0}')??0;
    final double kaloriKeluar = double.tryParse("${_laporanHarian?['total_kalori_out'] ?? 0}")??0;
    final double kaloriTarget = 2600;
     double sisaKalori = double.tryParse('${kaloriTarget - kaloriMasuk}')??0;
    if (sisaKalori <= 0) {
      sisaKalori = 0;
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLaporanHarian,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Kalori Header
                  Card(
                    color: sisaKalori > 0 ? Color(0xFFFF7D39) : Colors.redAccent,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monitor Kalori',
                            style: TextStyle(
                                fontSize: 18, color: Colors.white ,fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$kaloriMasuk' "/" '$kaloriTarget',
                            style: const TextStyle(
                                fontSize: 24,color : Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sisa: $sisaKalori kkal',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: kaloriMasuk / kaloriTarget > 1
                                ? 1
                                : kaloriMasuk / kaloriTarget,
                            backgroundColor: Color(0XFFFFCC9F),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNutriCard('Protein',
                            '${_laporanHarian?['total_protein'] ?? 0}g', Colors.black),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNutriCard('Karbo',
                            '${_laporanHarian?['total_karbo'] ?? 0}g', Colors.black),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNutriCard('Lemak',
                            '${_laporanHarian?['total_lemak'] ?? 0}g', Colors.black),
                      ),
                    ],
                  ),
                  // Date n time
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
      color: Color(0xFFFFDDDD),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black)),
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