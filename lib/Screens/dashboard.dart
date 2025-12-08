import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? _laporanHarian;
  bool _isLoading = true;

  double _kaloriTarget = 0;
  

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([_loadUserTarget(), _loadLaporanHarian()]);
  }

  Future<void> _loadUserTarget() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final res = await supabase
          .from('users')
          .select('tdee, target_mode, target_kalori')
          .eq('id_user', userId)
          .single();

      if (mounted) {
        setState(() {
          _kaloriTarget = (res['target_kalori'] as num?)?.toDouble() ??
              ((res['tdee'] as num?)?.toDouble() ?? 0);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLaporanHarian() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final today = DateTime.now().toIso8601String().split('T')[0];
      final res = await supabase
          .from('laporan_harian')
          .select()
          .eq('id_user', userId)
          .eq('tanggal', today)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _laporanHarian = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kaloriMasuk =
        (_laporanHarian?['total_kalori_in'] as num?)?.toDouble() ?? 0;
    final kaloriKeluar =
        (_laporanHarian?['total_kalori_out'] as num?)?.toDouble() ?? 0;
    final sisaKalori = (_kaloriTarget - kaloriMasuk).clamp(0, double.infinity);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _initializeData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: sisaKalori >= 0 ? const Color(0xFFFF7D39) : Colors.redAccent,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monitor Kalori',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$kaloriMasuk / $_kaloriTarget',
                            style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sisa: $sisaKalori kkal',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: (kaloriMasuk / _kaloriTarget).clamp(0, 1),
                            backgroundColor: const Color(0XFFFFCC9F),
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 150),
                  const Text(
                    'Makronutrien',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNutriCard(
                            'Protein',
                            '${_laporanHarian?['total_protein'] ?? 0}g',
                            Colors.black),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNutriCard(
                            'Karbo',
                            '${_laporanHarian?['total_karbo'] ?? 0}g',
                            Colors.black),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNutriCard(
                            'Lemak',
                            '${_laporanHarian?['total_lemak'] ?? 0}g',
                            Colors.black),
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
      color: const Color(0xFFFFDDDD),
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