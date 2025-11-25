import 'package:flutter/material.dart';
import 'package:langsingin/Screens/dashboard.dart';
import 'package:langsingin/main.dart';

class FoodLogPage extends StatelessWidget {
  const FoodLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Makanan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text('Halaman Log Makanan\n(Coming Soon)'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur tambah makanan coming soon!')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
