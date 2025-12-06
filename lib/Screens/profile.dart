import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:langsingin/Screens/login.dart';
import 'package:langsingin/main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  /* ---------- LOGOUT ---------- */
  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  /* ---------- UPDATE TARGET ---------- */
  Future<void> _updateTargetMode(String newMode) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final res = await supabase
        .from('users')
        .select('tdee')
        .eq('id_user', user.id)
        .single();

    final tdee = (res['tdee'] as num).toDouble();
    final newTarget = switch (newMode) {
      'bulking' => (tdee + 300).round(),
      'cutting' => (tdee - 300).round(),
      _ => tdee.round(),
    };

    await supabase.from('users').update({
      'target_mode': newMode,
      'target_kalori': newTarget,
    }).eq('id_user', user.id);

    await supabase.auth.updateUser(
      UserAttributes(data: {'target_mode': newMode}),
    );

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Target diubah menjadi ${newMode.capitalize()}')),
      );
    }
  }

  /* ---------- SELECTOR WIDGET ---------- */
  Widget _targetSelector() {
    final currentMode = supabase.auth.currentUser?.userMetadata?['target_mode'] ?? 'maintenance';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Target Kalori Harian',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _modeChip('maintenance', 'Maintenance')),
            const SizedBox(width: 8),
            Expanded(child: _modeChip('bulking', 'Bulking')),
            const SizedBox(width: 8),
            Expanded(child: _modeChip('cutting', 'Cutting')),
          ],
        ),
      ],
    );
  }

  Widget _modeChip(String mode, String label) {
    final isSelected = (supabase.auth.currentUser?.userMetadata?['target_mode'] ?? 'maintenance') == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _updateTargetMode(mode),
      selectedColor: const Color(0xFFFF5A16).withOpacity(.25),
      backgroundColor: Colors.grey[200],
    );
  }

  /* ---------- BUILD ---------- */
  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final displayName = user?.userMetadata?['nama_lengkap'] ?? 'Pengguna';
    final email = user?.email ?? '-';

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
              Text(displayName, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 24),
            ],
          ),

          _targetSelector(), // <--- selector target kalori

          const SizedBox(height: 24),
          _menuTile(Icons.edit, 'Edit Profile', onTap: () => _comingSoon()),
          _divider(),
          _menuTile(Icons.settings, 'Pengaturan', onTap: () => _comingSoon()),
          _divider(),
          _menuTile(Icons.help, 'Bantuan', onTap: () => _comingSoon()),
          _divider(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ---------- HELPERS ---------- */
  Widget _menuTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black54),
      dense: true,
      onTap: onTap,
    );
  }

  Widget _divider() => const Divider(height: 0, thickness: .5);
  void _comingSoon() => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coming soon!')),
      );
}

/* extension agar .capitalize() tersedia */
extension StringExt on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}