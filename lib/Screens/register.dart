import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:langsingin/Screens/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final supabase = Supabase.instance.client;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  /* ---------- CONTROLLERS ---------- */
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _bodyFatCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();

  /* ---------- STATE ---------- */
  String? _selectedGender;
  String? _activityLevel;
  int _currentStep = 0;
  bool _loading = false;
  DateTime? _selectedDate;

  /* ---------- CALCULATED ---------- */
  double _bmi = 0;
  double _bmr = 0;
  double _tdee = 0;
  int _maintenance = 0;
  int _surplus = 0;
  int _deficit = 0;
  int _age = 0;

  /* ---------- NAMA DEPAN UNTUK STEP 1 ---------- */
  String _namaDepan = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _usernameCtrl.dispose();
    _firstNameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _bodyFatCtrl.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  /* ---------- NAVIGASI STEP ---------- */
  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep == 0) _namaDepan = _firstNameCtrl.text.trim(); // SIMPAN NAMA
    if (_currentStep < 6) {
      setState(() => _currentStep++);
      if (_currentStep == 5) _calculateCalories();
    }
  }

  void _prevStep() {
  if (_currentStep > 0) {
    setState(() => _currentStep--);
  } else {
    // step-0 → baru ke login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }
}

  /* ---------- VALIDASI PER STEP ---------- */
  bool _validateCurrentStep() {
    String? error;
    switch (_currentStep) {
      case 0:
        if (_firstNameCtrl.text.isEmpty) error = 'Nama depan harus diisi!';
        break;
      case 2:
        final h = double.tryParse(_heightCtrl.text);
        final w = double.tryParse(_weightCtrl.text);
        if (h == null || w == null || h < 50 || h > 250 || w < 20 || w > 300) {
          error = 'Tinggi (50-250 cm) & berat (20-300 kg) harus valid!';
        }
        break;
      case 3:
        if (_birthDateCtrl.text.isEmpty || _selectedDate == null) {
          error = 'Tanggal lahir harus dipilih!';
        } else if (_selectedGender == null) {
          error = 'Jenis kelamin harus dipilih!';
        }
        break;
      case 4:
        if (_activityLevel == null) error = 'Level aktivitas harus dipilih!';
        break;
      case 6:
        if (_emailCtrl.text.isEmpty ||
            _usernameCtrl.text.isEmpty ||
            _passCtrl.text.isEmpty ||
            _passCtrl.text.length < 6) {
          error = 'Lengkapi email, nama pengguna & password (min 6 karakter)!';
        }
        break;
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return false;
    }
    return true;
  }

  /* ---------- HITUNG KALORI ---------- */
  void _calculateCalories() {
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final h = double.tryParse(_heightCtrl.text) ?? 0;
    final heightM = h / 100;
    _bmi = w / (heightM * heightM);

    _bmr = (_selectedGender == 'Laki-laki')
        ? (10 * w) + (6.25 * h) - (5 * _age) + 5
        : (10 * w) + (6.25 * h) - (5 * _age) - 161;

    double factor = 1.2;
    switch (_activityLevel) {
      case 'Ringan':
        factor = 1.375;
        break;
      case 'Sedang':
        factor = 1.55;
        break;
      case 'Berat':
        factor = 1.725;
        break;
      case 'Sangat Berat':
        factor = 1.9;
        break;
    }
    _tdee = _bmr * factor;
    _maintenance = _tdee.round();
    _surplus = _maintenance + 300;
    _deficit = _maintenance - 300;
  }

  /* ---------- PILIH TANGGAL ---------- */
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2006),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthDateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
        _age = DateTime.now().year - picked.year;
      });
    }
  }

  /* ---------- MAPPING AKTIVITAS ---------- */
  String _toDbActivity(String? val) {
    switch (val) {
      case 'Rendah':
        return 'Jarang Bergerak';
      case 'Ringan':
        return 'Ringan';
      case 'Sedang':
        return 'Menengah';
      case 'Berat':
        return 'Berat';
      case 'Sangat Berat':
        return 'Sangat Berat';
      default:
        return 'Jarang Bergerak';
    }
  }

  /* ---------- REGISTRASI ---------- */
  Future<void> _register() async {
    if (!_validateCurrentStep()) return;
    setState(() => _loading = true);
    try {
      final authRes = await supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (authRes.user == null) throw Exception('Gagal membuat akun');

      await supabase.from('users').insert({
        'id_user': authRes.user!.id,
        'nama_lengkap': _firstNameCtrl.text.trim(),
        'berat': double.tryParse(_weightCtrl.text),
        'tinggi': double.tryParse(_heightCtrl.text),
        'usia': _age,
        'jenis_kelamin': _selectedGender,
        'level_aktivitas': _toDbActivity(_activityLevel),
        'bmi': _bmi,
        'bmr': _bmr,
        'tdee': _tdee,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Silakan verifikasi email terlebih dahulu.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ---------- UI ---------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // biar gradasi tetap penuh
  appBar: AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    automaticallyImplyLeading: false, // tidak perlu tombol back otomatis
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: _prevStep,
    ),
  ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0XFFEBD1B7)),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  _buildProgressIndicator(),
                  const SizedBox(height: 24),
                  _buildStepContent(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_currentStep > 0)
                        TextButton(onPressed: _prevStep, child: const Text('Kembali'))
                      else
                        const SizedBox.shrink(),
                      ElevatedButton(
                        onPressed: _loading
                            ? null
                            : (_currentStep == 6 ? _register : _nextStep),
                        child: _loading
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : Text(_currentStep == 6 ? 'Daftar' : 'Lanjut'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /* ---------- WIDGET BANTU ---------- */
  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index <= _currentStep ? Colors.orange : Colors.white54,
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildRDIInfoStep();
      case 2:
        return _buildBodyDataStep();
      case 3:
        return _buildBirthAndGenderStep();
      case 4:
        return _buildActivityStep();
      case 5:
        return _buildCalorieResultStep();
      case 6:
        return _buildFinalFormStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameStep() {
    return _cardForm([
      const Text('Apa nama depanmu?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      TextField(
  controller: _firstNameCtrl,
  style: const TextStyle(color: Color(0XFFA8A8A8)),          // <- teks putih
  cursorColor: Colors.white,                            // <- cursor putih
  decoration: InputDecoration(
    labelText: 'Nama depan',
    labelStyle: const TextStyle(color: Color(0XFFA8A8A8)), // label abu2
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    filled: true,
    fillColor: Colors.black,                            // background hitam
  ),
)
    ]);
  }

  Widget _buildRDIInfoStep() {
    return _cardForm([
      const SizedBox(height: 16),
      Text(
        'Oke $_namaDepan. Kita hitung dulu RDI-mu ya', // << NAMA TERPAKAI
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      const Text(
        'RDI adalah singkatan dari Recommended Daily Intake atau Asupan Harian yang Direkomendasikan. Ini adalah jumlah rata-rata asupan nutrisi harian yang cukup untuk memenuhi kebutuhan hampir semua individu sehat dalam kelompok usia dan jenis kelamin tertentu, dan biasanya digunakan sebagai panduan gizi.',
        textAlign: TextAlign.justify,
        style: TextStyle(color: Colors.black54),
      ),
    ]);
  }

  Widget _buildBodyDataStep() {
    return _cardForm([
      const Text('Tinggi, berat badan, dan lemak tubuh',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(
        controller: _heightCtrl,
        decoration: InputDecoration(
          labelText: 'Tinggi (cm)',
          prefixIcon: const Icon(Icons.height),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _weightCtrl,
        decoration: InputDecoration(
          labelText: 'Berat (kg)',
          prefixIcon: const Icon(Icons.monitor_weight),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _bodyFatCtrl,
        decoration: InputDecoration(
          labelText: 'Lemak tubuh (%) - opsional',
          prefixIcon: const Icon(Icons.percent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: TextInputType.number,
      ),
    ]);
  }

  Widget _buildBirthAndGenderStep() {
    return _cardForm([
      const Text('Tanggal lahir dan jenis kelamin',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(
        controller: _birthDateCtrl,
        decoration: InputDecoration(
          labelText: 'Tanggal lahir',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        readOnly: true,
        onTap: _selectDate,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _selectedGender,
        items: ['Laki-laki', 'Perempuan']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (val) => setState(() => _selectedGender = val),
        decoration: InputDecoration(
          labelText: 'Jenis kelamin',
          prefixIcon: const Icon(Icons.people),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    ]);
  }

  Widget _buildActivityStep() {
    return _cardForm([
      const Text('Level aktivitas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      _activityRadio('Rendah', 'Sebagian besar waktu duduk'),
      _activityRadio('Ringan', 'Olahraga ringan 1–3 kali seminggu'),
      _activityRadio('Sedang', 'Olahraga 3–5 kali seminggu'),
      _activityRadio('Berat', 'Latihan intens hampir setiap hari'),
      _activityRadio('Sangat Berat', 'Kerja fisik berat sepanjang hari'),
    ]);
  }

  Widget _activityRadio(String label, String desc) {
    return RadioListTile<String>(
      title: Text(label),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      value: label,
      groupValue: _activityLevel,
      onChanged: (val) => setState(() => _activityLevel = val),
      activeColor: Colors.orange,
    );
  }

  Widget _buildCalorieResultStep() {
    return _cardForm([
      const Icon(Icons.local_fire_department, size: 60, color: Colors.orange),
      const SizedBox(height: 16),
      const Text('Kesimpulan kalori harianmu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      _calorieCard('Maintenance', _maintenance, Colors.blue),
      const SizedBox(height: 12),
      _calorieCard('Surplus (Bulking)', _surplus, Colors.green),
      const SizedBox(height: 12),
      _calorieCard('Deficit (Cutting)', _deficit, Colors.red),
      const SizedBox(height: 16),
      Text(
        'BMI: ${_bmi.toStringAsFixed(1)} | BMR: ${_bmr.toStringAsFixed(0)} | TDEE: ${_tdee.toStringAsFixed(0)}',
        style: const TextStyle(fontSize: 12, color: Colors.black54),
        textAlign: TextAlign.center,
      ),
    ]);
  }

  Widget _calorieCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
          Text('$value kkal',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFinalFormStep() {
    return _cardForm([
      const Text('Masukkan email dan password',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(
        controller: _emailCtrl,
        decoration: InputDecoration(
          labelText: 'Email',
          prefixIcon: const Icon(Icons.email),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _usernameCtrl,
        decoration: InputDecoration(
          labelText: 'Nama pengguna',
          prefixIcon: const Icon(Icons.person_outline),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _passCtrl,
        decoration: InputDecoration(
          labelText: 'Kata sandi',
          prefixIcon: const Icon(Icons.lock),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        obscureText: true,
      ),
      const SizedBox(height: 8),
      const Text('Minimal 6 karakter',
          style: TextStyle(fontSize: 12, color: Colors.black54)),
    ]);
  }

  Widget _cardForm(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}