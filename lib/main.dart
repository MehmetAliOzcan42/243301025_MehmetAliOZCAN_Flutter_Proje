import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';

void main() async {
  // async zamanlayıcı, Supabase'in başlatılması sırasında bekleme yapmamızı sağlar.
  WidgetsFlutterBinding.ensureInitialized();
  // Flutter'ın başlatılmadan önce Supabase için gerekli hazırlıkları yapmasını sağlar.

  await Supabase.initialize(
    // Supabase ile iletişim kurar ve await ile tamamlanmasını bekler.
    url: 'https://uotvqlzctrokajrbipmk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVvdHZxbHpjdHJva2FqcmJpcG1rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzMTM0ODQsImV4cCI6MjA5Mzg4OTQ4NH0.QmWilL0ze42XPj0VJZYPK1t4c04ZzJOmjf3w9VYFLPk',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diş Kliniği Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal, // Uygulamanın ana renk temasını belirler.
        useMaterial3: true,
        // Flutter'ın en yeni Material Design 3 özellikleri için kullanılır.
        fontFamily: 'Roboto',
      ),
      home: const AuthScreen(),
    );
  }
}
