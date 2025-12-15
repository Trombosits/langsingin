import 'dart:developer' as dev;

/// Utility untuk menghitung waktu eksekusi (ms) setiap aksi
class Performance {
  final int _start = DateTime.now().millisecondsSinceEpoch;
  final String _operation;

  Performance(this._operation) {
    dev.log('🚀 $_operation  |  start', name: 'Performance');
  }

  /// Catat selisih waktu sejak objek dibuat
  void lap([String? tag]) {
    final ms = DateTime.now().millisecondsSinceEpoch - _start;
    dev.log('⏱️  $_operation${tag != null ? ' : $tag' : ''}  |  $ms ms', name: 'Performance');
  }

  /// Selesai & cetak total
  void finish() {
    final ms = DateTime.now().millisecondsSinceEpoch - _start;
    dev.log('✅ $_operation  |  TOTAL  $ms ms', name: 'Performance');
  }
}

