import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    with TickerProviderStateMixin {
  /* ----- tab controller ----- */
  late TabController _tabCtrl;

  /* ----- makanan ----- */
  final _foodSearchCtrl = TextEditingController();
  final _foodItems = <FoodItem>[];
  List<dynamic> _foodList = [];
  bool _loadingFood = false;

  /* ----- olahraga ----- */
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
    setState(() => _loadingFood = true);
    try {
      final res = await supabase
          .from('makanan')
          .select('id_makanan, nama_makanan')
          .ilike('nama_makanan', '%$keyword%')
          .limit(20);
      if (!mounted) return;
      setState(() => _foodList = res);
      if (_foodList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ditemukan')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingFood = false);
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
     OLAHRAGA FUNCTIONS
  ================================================= */
  Future<void> _searchActivity() async {
    final keyword = _activitySearchCtrl.text.trim();
    if (keyword.isEmpty) return;
    setState(() => _loadingAct = true);
    try {
      final res = await supabase
          .from('aktivitas')
          .select('id_aktivitas, nama_aktivitas')
          .ilike('nama_aktivitas', '%$keyword%')
          .limit(20);
      if (!mounted) return;
      setState(() => _activityList = res);
      if (_activityList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ditemukan')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingAct = false);
    }
  }

  void _addActivity(int id, String nama) {
    setState(() {
      _activityItems.add(ActivityItem(
        idAktivitas: id,
        namaAktivitas: nama,
        menit: 0,
        tanggal: _selectedDate,
      ));
    });
  }

  void _removeActivity(int index) =>
      setState(() => _activityItems.removeAt(index));

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

    setState(() => _loadingFood = true); // reuse flag
    try {
      final userId = supabase.auth.currentUser!.id;

      /* ---------- insert makanan ---------- */
      if (_foodItems.isNotEmpty) {
        final foodBatch = _foodItems.map((it) => {
          'id_user': userId,
          'id_makanan': it.idMakanan,
          'porsi_gram': it.gram,
          'tanggal_catat': it.tanggal.toIso8601String().split('T')[0],
        }).toList();
        await supabase.from('log_makanan').insert(foodBatch);
      }

      /* ---------- insert aktivitas ---------- */
      if (_activityItems.isNotEmpty) {
        final actBatch = _activityItems.map((it) => {
          'id_user': userId,
          'id_aktivitas': it.idAktivitas,
          'durasi_menit': it.menit,
          'tanggal_catat': it.tanggal.toIso8601String().split('T')[0],
        }).toList();
        await supabase.from('log_aktivitas').insert(actBatch);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua log tersimpan ✅')),
      );
      _reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingFood = false);
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
     UI
  ================================================= */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Makanan & Olahraga'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Makanan'),
            Tab(icon: Icon(Icons.directions_run), text: 'Olahraga'),
          ],
        ),
      ),
      body: Column(
        children: [
          /* ----- konten tab ----- */
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildFoodTab(),
                _buildActivityTab(),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loadingFood ? null : _saveAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7C36),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loadingFood
                      ? const CircularProgressIndicator()
                      : const Text('Simpan Semua Log'),
                ),
              ),
            ),
          ),
          
        ],
      ),
      
    );
  }

  /* -------------------------------------------------
     WIDGET TAB MAKANAN
  ------------------------------------------------- */
  Widget _buildFoodTab() {
    return Column(
      children: [
        /* pencarian */
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
        ),
        /* hasil pencarian */
        if (_loadingFood)
          const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
        else if (_foodList.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
            height: 150,
            child: Scrollbar(
              child: ListView.builder(
                itemCount: _foodList.length,
                itemBuilder: (_, i) {
                  final m = _foodList[i];
                  return ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: Text(m['nama_makanan']),
                    onTap: () => _addFood(m['id_makanan'], m['nama_makanan']),
                  );
                },
              ),
            ),
          ),
        /* daftar item */
        Expanded(
          child: _foodItems.isEmpty
              ? const Center(child: Text('Belum ada makanan'))
              : ListView.builder(
                  itemCount: _foodItems.length,
                  itemBuilder: (_, i) {
                    final it = _foodItems[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        ),
      ],
    );
  }

  /* -------------------------------------------------
     WIDGET TAB OLAHRAGA
  ------------------------------------------------- */
  Widget _buildActivityTab() {
    return Column(
      children: [
        /* pencarian */
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
        ),
        /* hasil pencarian */
        if (_loadingAct)
          const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
        else if (_activityList.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
            height: 150,
            child: Scrollbar(
              child: ListView.builder(
                itemCount: _activityList.length,
                itemBuilder: (_, i) {
                  final a = _activityList[i];
                  return ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: Text(a['nama_aktivitas']),
                    onTap: () => _addActivity(a['id_aktivitas'], a['nama_aktivitas']),
                  );
                },
              ),
            ),
          ),
        /* daftar item */
        Expanded(
          child: _activityItems.isEmpty
              ? const Center(child: Text('Belum ada aktivitas'))
              : ListView.builder(
                  itemCount: _activityItems.length,
                  itemBuilder: (_, i) {
                    final it = _activityItems[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        ),
      ],
    );
  }
}