import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

/* -------------------------------------------------
   MODEL DATA
------------------------------------------------- */
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

/* -------------------------------------------------
   HALAMAN UTAMA
------------------------------------------------- */
class FoodLogPage extends StatefulWidget {
  const FoodLogPage({super.key});

  @override
  State<FoodLogPage> createState() => _FoodLogPageState();
}

class _FoodLogPageState extends State<FoodLogPage> {
  final _foodSearchCtrl = TextEditingController();

  final _items = <FoodItem>[];
  List<dynamic> _foodList = [];
  bool _loading = false;

  DateTime _selectedDate = DateTime.now();

  /* ---------- CARI MAKANAN ---------- */
  Future<void> _searchFood() async {
    final keyword = _foodSearchCtrl.text.trim();
    if (keyword.isEmpty) return;

    setState(() => _loading = true);
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
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ---------- TAMBAH ITEM KE BAWAH ---------- */
  void _addItem(int idMakanan, String nama) {
    setState(() {
      _items.add(FoodItem(
        idMakanan: idMakanan,
        namaMakanan: nama,
        gram: 0,
        tanggal: _selectedDate,
      ));
    });
  }

  /* ---------- HAPUS ITEM ---------- */
  void _removeItem(int index) => setState(() => _items.removeAt(index));

  /* ---------- SIMPAN SEMUA ---------- */
  Future<void> _saveAll() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 makanan')),
      );
      return;
    }
    // validasi cepat
    for (var it in _items) {
      if (it.gram <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${it.namaMakanan} belum diisi gramnya')),
        );
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final batch = _items.map((it) => {
        'id_user': userId,
        'id_makanan': it.idMakanan,
        'porsi_gram': it.gram,
        'tanggal_catat': it.tanggal.toIso8601String().split('T')[0],
      }).toList();

      await supabase.from('log_makanan').insert(batch);

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
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    _foodSearchCtrl.clear();
    _foodList.clear();
    _items.clear();
    _selectedDate = DateTime.now();
    setState(() {});
  }

  @override
  void dispose() {
    _foodSearchCtrl.dispose();
    super.dispose();
  }

  /* -------------------------------------------------
     UI
  ------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Makanan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          /* ---------- PENCARIAN ---------- */
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _foodSearchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Cari makanan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchFood(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _searchFood,
                  icon: const Icon(Icons.search, size: 32),
                ),
              ],
            ),
          ),

          /* ---------- HASIL CARI (TETAP TERBUKA) ---------- */
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (_foodList.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              height: 150,
              child: Scrollbar(
                child: ListView.builder(
                  itemCount: _foodList.length,
                  itemBuilder: (_, i) {
                    final m = _foodList[i];
                    return ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: Text(m['nama_makanan']),
                      onTap: () => _addItem(m['id_makanan'], m['nama_makanan']),
                    );
                  },
                ),
              ),
            ),

          /* ---------- DAFTAR ITEM YANG SUDAH DIPILIH ---------- */
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Belum ada makanan'))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final it = _items[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              /* nama */
                              Expanded(
                                flex: 3,
                                child: Text(it.namaMakanan,
                                    style: const TextStyle(fontWeight: FontWeight.w500)),
                              ),
                              /* gram */
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Gram',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (v) =>
                                      it.gram = int.tryParse(v) ?? 0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              /* tanggal */
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: () async {
                                    final pick = await showDatePicker(
                                      context: context,
                                      initialDate: it.tanggal,
                                      firstDate: DateTime.now()
                                          .subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now(),
                                    );
                                    if (pick != null) setState(() => it.tanggal = pick);
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text('${it.tanggal.day}/${it.tanggal.month}/${it.tanggal.year}'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              /* hapus */
                              IconButton(
                                onPressed: () => _removeItem(i),
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          /* ---------- TOMBOL SIMPAN SEMUA ---------- */
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7C36),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
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
}