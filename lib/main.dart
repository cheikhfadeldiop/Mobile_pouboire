import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TipCalculatorApp());
}

/// Application principale avec support du mode clair et sombre.
class TipCalculatorApp extends StatefulWidget {
  const TipCalculatorApp({super.key});

  @override
  State<TipCalculatorApp> createState() => _TipCalculatorAppState();
}

class _TipCalculatorAppState extends State<TipCalculatorApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculatrice de Pourboire',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: SplashScreen(onToggleTheme: _toggleTheme),
    );
  }
}
