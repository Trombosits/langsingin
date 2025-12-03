// fetchTrenKalori.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class TrenKaloriRepository {
  TrenKaloriRepository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<List<double>> fetchWeeklyCalories({required String userId}) async {
    // Default semua hari = 0
    final List<double> result = List.generate(7, (_) => 0.0);

    // Hitung awal & akhir minggu (berdasarkan hari ini)
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Senin
    final endOfWeek = startOfWeek.add(const Duration(days: 6));       // Minggu

    // Format tanggal ke yyyy-MM-dd (supaya cocok dengan kolom "date" di Postgres)
    String toDateString(DateTime d) => d.toIso8601String().substring(0, 10);

    final data = await _supabase
        .from('laporan_mingguan') // <-- GANTI ke nama view kamu
        .select()
        .eq('id_user', userId)
        .gte('tanggal', toDateString(startOfWeek))
        .lte('tanggal', toDateString(endOfWeek));

    for (final row in data) {
      // Ambil tanggal
      final dynamic tglRaw = row['tanggal'];

      DateTime? tanggal;
      if (tglRaw is String) {
        tanggal = DateTime.tryParse(tglRaw);
      } else if (tglRaw is DateTime) {
        tanggal = tglRaw;
      }

      if (tanggal == null) continue;

      // weekday: 1 = Senin ... 7 = Minggu
      final int index = tanggal.weekday - 1;
      if (index < 0 || index > 6) continue;

      // Pilih kolom kalori yang mau ditampilkan
      final num? totalKalori = row['total_kalori_in']; 
      // Atau kalau mau selisih:
      // final num? totalKalori = row['selisih_kalori'];

      if (totalKalori != null) {
        result[index] = totalKalori.toDouble();
      }
    }

    return result;
  }
}
