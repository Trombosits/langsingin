import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:langsingin/Utility/performance.dart';

final supabase = Supabase.instance.client;

/* =================================================
   MODEL MAKANAN
================================================= */
class FoodItem {
  int idMakanan;
  String namaMakanan;
  int gram;
  DateTime tanggal;

  FoodItem({
    required this.idMakanan,
    required this.namaMakanan,
    this.gram = 0,
    required this.tanggal,
  });
}

/* =================================================
   MODEL AKTIVITAS / OLAHRAGA
================================================= */
class ActivityItem {
  int idAktivitas;
  String namaAktivitas;
  int menit;
  DateTime tanggal;

  ActivityItem({
    required this.idAktivitas,
    required this.namaAktivitas,
    this.menit = 0,
    required this.tanggal,
  });
}

/* =================================================
   HALAMAN UTAMA (TAB MAKANAN & OLAHRAGA)
================================================= */
class FoodLogPage extends StatefulWidget {
  const FoodLogPage({super.key});

  @override
  State<FoodLogPage> createState() => _FoodLogPageState();
}

class _FoodLogPageState extends State<FoodLogPage>
    with SingleTickerProviderStateMixin {
  /* ---------- TAB ---------- */
  late TabController _tabCtrl;

  /* ---------- MAKANAN ---------- */
  final _foodSearchCtrl = TextEditingController();
  final _foodItems = <FoodItem>[];
  List<dynamic> _foodList = [];
  bool _loadingFood = false;

  /* ---------- AKTIVITAS ---------- */
  final _activitySearchCtrl = TextEditingController();
  final _activityItems = <ActivityItem>[];
  List<dynamic> _activityList = [];
  bool _loadingAct = false;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _foodSearchCtrl.dispose();
    _activitySearchCtrl.dispose();
    super.dispose();
  }

  /* =================================================
     MAKANAN FUNCTIONS
  ================================================= */
  Future<void> _searchFood() async {
    final keyword = _foodSearchCtrl.text.trim();
    if (keyword.isEmpty) return;
     final perf = Performance('Search Food'); // ⏱️ start
  setState(() => _loadingFood = true);

  try {
    final res = await supabase
        .from('makanan')
        .select('id_makanan, nama_makanan')
        .ilike('nama_makanan', '%$keyword%')
        .limit(20);
    if (!mounted) return;

    setState(() => _foodList = res);
    perf.lap('API return'); // ⏱️ setelah API selesai

    if (_foodList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ditemukan')),
      );
    }
  } catch (e) {
    perf.lap('error');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
  } finally {
    if (mounted) setState(() => _loadingFood = false);
    perf.finish(); // ⏱️ total selesai
  }
}

  void _addFood(int id, String nama) {
    setState(() {
      _foodItems.add(FoodItem(
        idMakanan: id,
        namaMakanan: nama,
        gram: 0,
        tanggal: _selectedDate,
      ));
    });
  }

  void _removeFood(int index) => setState(() => _foodItems.removeAt(index));

  /* =================================================
     AKTIVITAS FUNCTIONS
  ================================================= */
  Future<void> _searchActivity() async {
  final keyword = _activitySearchCtrl.text.trim();
  if (keyword.isEmpty) return;

  final perf = Performance('Search Activity'); // ⏱️ start
  setState(() => _loadingAct = true);

  try {
    final res = await supabase
        .from('aktivitas')
        .select('id_aktivitas, nama_aktivitas')
        .ilike('nama_aktivitas', '%$keyword%')
        .limit(20);
    if (!mounted) return;

    setState(() => _activityList = res);
    perf.lap('API return'); // ⏱️ setelah API selesai

    if (_activityList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ditemukan')),
      );
    }
  } catch (e) {
    perf.lap('error');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
  } finally {
    if (mounted) setState(() => _loadingAct = false);
    perf.finish(); // ⏱️ total selesai
  }
}

  void _addActivity(int id, String nama) {
  final perf = Performance('Add Activity'); // ⏱️ start
  setState(() {
    _activityItems.add(ActivityItem(
      idAktivitas: id,
      namaAktivitas: nama,
      menit: 0,
      tanggal: _selectedDate,
    ));
  });
  perf.lap('UI updated'); // ⏱️ setelah UI ditambah
  perf.finish(); // ⏱️ total selesai
}
  void _removeActivity(int index) {
  final perf = Performance('Remove Activity'); // ⏱️ start
  setState(() => _activityItems.removeAt(index));
  perf.lap('UI updated'); // ⏱️ setelah UI dihapus
  perf.finish(); // ⏱️ total selesai
}

  /* =================================================
     SIMPAN SEMUA (BATCH INSERT)
  ================================================= */
  Future<void> _saveAll() async {
  if (_foodItems.isEmpty && _activityItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tambahkan minimal 1 item')),
    );
    return;
  }

  /* validasi cepat */
  for (var it in _foodItems) {
    if (it.gram <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${it.namaMakanan} belum diisi gramnya')),
      );
      return;
    }
  }
  for (var it in _activityItems) {
    if (it.menit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${it.namaAktivitas} belum diisi menitnya')),
      );
      return;
    }
  }

  final perf = Performance('Save All Log'); // ⏱️ start
  setState(() => _loadingFood = true);

  try {
    final userId = supabase.auth.currentUser!.id;

    /* insert makanan */
    if (_foodItems.isNotEmpty) {
      final foodBatch = _foodItems.map((it) => {
        'id_user': userId,
        'id_makanan': it.idMakanan,
        'porsi_gram': it.gram,
        'tanggal_catat': it.tanggal.toIso8601String().split('T')[0],
      }).toList();
      await supabase.from('log_makanan').insert(foodBatch);
      perf.lap('insert food done');
    }

    /* insert aktivitas */
    if (_activityItems.isNotEmpty) {
      final actBatch = _activityItems.map((it) => {
        'id_user': userId,
        'id_aktivitas': it.idAktivitas,
        'durasi_menit': it.menit,
        'tanggal_catat': it.tanggal.toIso8601String().split('T')[0],
      }).toList();
      await supabase.from('log_aktivitas').insert(actBatch);
      perf.lap('insert activity done');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Semua log tersimpan ✅')),
    );
    _reset();
  } catch (e) {
    perf.lap('error');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
  } finally {
    if (mounted) setState(() => _loadingFood = false);
    perf.finish(); // ⏱️ total waktu simpan
  }
}

  void _reset() {
    _foodSearchCtrl.clear();
    _activitySearchCtrl.clear();
    _foodList.clear();
    _activityList.clear();
    _foodItems.clear();
    _activityItems.clear();
    _selectedDate = DateTime.now();
    setState(() {});
  }

  /* =================================================
     UI – TAB BAR
  ================================================= */
  @override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {
      FocusScope.of(context).unfocus();
      if (mounted) {
        setState(() {
          _foodList.clear();
          _activityList.clear();
        });
      }
    },
    child: Scaffold(
      backgroundColor: const Color(0XFFEBD1B7), // <- samakan dengan background
      appBar: AppBar(
        automaticallyImplyLeading: false, // <- hilangkan tombol back
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xffff7c36),
          indicatorColor: const Color(0xffff7c36),
          tabs: const [
            Tab(text: 'Makanan', icon: Icon(Icons.restaurant)),
            Tab(text: 'Aktivitas', icon: Icon(Icons.directions_run)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildFoodTab(),
          _buildActivityTab(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loadingFood ? null : _saveAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffff7c36),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loadingFood
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Simpan'),
            ),
          ),
        ),
      ),
    ),
  );
}
  /* =================================================
     TAB MAKANAN
  ================================================= */
  Widget _buildFoodTab() {
    return Scrollbar(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /* pencarian */
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _foodSearchCtrl,
                  decoration: InputDecoration(
                    labelText: 'Cari makanan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchFood(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _searchFood, icon: const Icon(Icons.search, size: 32)),
            ],
          ),
          const SizedBox(height: 12),

          /* hasil pencarian */
          if (_loadingFood)
            const Center(child: CircularProgressIndicator())
          else if (_foodList.isNotEmpty)
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0XFFFFF2E3),
              ),
              child: Scrollbar(
                child: ListView.builder(
                  itemCount: _foodList.length,
                  itemBuilder: (_, i) {
                    final m = _foodList[i];
                    return ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: Text(m['nama_makanan']),
                      onTap: () {
                        _addFood(m['id_makanan'], m['nama_makanan']);
                        setState(() => _foodList.clear());
                      },
                    );
                  },
                ),
              ),
            ),

          /* daftar item */
          if (_foodItems.isEmpty && _foodList.isEmpty)
            const Center(child: Text('Belum ada makanan'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: _foodItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final it = _foodItems[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(it.namaMakanan, style: const TextStyle(fontWeight: FontWeight.w500))),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Gram', border: OutlineInputBorder()),
                            onChanged: (v) => it.gram = int.tryParse(v) ?? 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () async {
                              final pick = await showDatePicker(
                                context: context,
                                initialDate: it.tanggal,
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now(),
                              );
                              if (pick != null) setState(() => it.tanggal = pick);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              child: Text('${it.tanggal.day}/${it.tanggal.month}/${it.tanggal.year}'),
                            ),
                          ),
                        ),
                        IconButton(onPressed: () => _removeFood(i), icon: const Icon(Icons.delete, color: Colors.red)),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /* =================================================
     TAB AKTIVITAS
  ================================================= */
  Widget _buildActivityTab() {
    return Scrollbar(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _activitySearchCtrl,
                  decoration: InputDecoration(
                    labelText: 'Cari aktivitas',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchActivity(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _searchActivity, icon: const Icon(Icons.search, size: 32)),
            ],
          ),
          const SizedBox(height: 12),

          if (_loadingAct)
            const Center(child: CircularProgressIndicator())
          else if (_activityList.isNotEmpty)
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0XFFFFF2E3),
              ),
              child: Scrollbar(
                child: ListView.builder(
                  itemCount: _activityList.length,
                  itemBuilder: (_, i) {
                    final a = _activityList[i];
                    return ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: Text(a['nama_aktivitas']),
                      onTap: () {
                        _addActivity(a['id_aktivitas'], a['nama_aktivitas']);
                        setState(() => _activityList.clear());
                      },
                    );
                  },
                ),
              ),
            ),

          if (_activityItems.isEmpty && _activityList.isEmpty)
            const Center(child: Text('Belum ada aktivitas'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: _activityItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final it = _activityItems[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(it.namaAktivitas, style: const TextStyle(fontWeight: FontWeight.w500))),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Menit', border: OutlineInputBorder()),
                            onChanged: (v) => it.menit = int.tryParse(v) ?? 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () async {
                              final pick = await showDatePicker(
                                context: context,
                                initialDate: it.tanggal,
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now(),
                              );
                              if (pick != null) setState(() => it.tanggal = pick);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              child: Text('${it.tanggal.day}/${it.tanggal.month}/${it.tanggal.year}'),
                            ),
                          ),
                        ),
                        IconButton(onPressed: () => _removeActivity(i), icon: const Icon(Icons.delete, color: Colors.red)),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}