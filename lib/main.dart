import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_menu_screen.dart';

void main() {
  runApp(const ProviderScope(child: CrusadeCommandApp()));
}

class CrusadeCommandApp extends StatelessWidget {
  const CrusadeCommandApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0A120D); // Dark Angels very dark green
    const panel = Color(0xFF111C15);
    const bone = Color(0xFFE5D5B3); // Deathwing bone

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dark Angels: Crusade Command',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: bone,
          brightness: Brightness.dark,
          surface: panel,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.w800),
          headlineMedium: TextStyle(fontWeight: FontWeight.w800),
          titleLarge: TextStyle(fontWeight: FontWeight.w800),
          titleMedium: TextStyle(fontWeight: FontWeight.w700),
          labelLarge: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}
