import 'package:flutter/material.dart';
// Kendi dosya yoluna göre burayı kontrol et:
// Eğer lib/screens/auth_screen.dart ise:
import 'package:dis_klinigi/screens/auth_screen.dart';

void main() {
  // TODO: Supabase başlatma kodu buraya gelecek
  // WidgetsFlutterBinding.ensureInitialized();
  // await Supabase.initialize(url: 'YOUR_URL', anonKey: 'YOUR_KEY');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diş Kliniği',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // İLK EKRAN
      home: const AuthScreen(),
    );
  }
}
