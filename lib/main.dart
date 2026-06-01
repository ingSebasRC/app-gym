import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Corregimos el import basándonos en tu estructura de carpetas
import 'pantallas/principal.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRONLOG',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const PantallaPrincipal(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE8FF00),
        onPrimary: Color(0xFF0A0A0A),
        secondary: Color(0xFF1C1C1C),
        onSecondary: Color(0xFFFFFFFF),
        surface: Color(0xFF111111),
        onSurface: Color(0xFFFFFFFF),
        outline: Color(0xFF2A2A2A),
        error: Color(0xFFFF4444),
      ),
      // Eliminamos la línea de fontFamily: 'Barlow' para evitar errores
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 72,
          fontWeight: FontWeight.w900,
          letterSpacing: -2,
          color: Color(0xFFFFFFFF),
          height: 0.95,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: Color(0xFFFFFFFF),
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Color(0xFFFFFFFF),
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: Color(0xFF888888),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFFCCCCCC),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF888888),
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: Color(0xFFE8FF00),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E1E1E),
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF888888),
        size: 22,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFE8FF00),
        foregroundColor: Color(0xFF0A0A0A),
        elevation: 0,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF161616),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8FF00), width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF444444), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}