import 'package:flutter/material.dart';
import 'package:langsingin/Screens/homepage.dart';
import 'package:langsingin/Screens/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  
   await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANONKEY']!,
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LangsingIn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFE3C7),
        useMaterial3: true,
      ),
      home: supabase.auth.currentSession != null
          ? const HomePage()
          : const LoginPage(),
    );
  }
}
// ========================================
// FOOD LOG PAGE
// ========================================

// ========================================
// PROFILE PAGE
// ========================================
