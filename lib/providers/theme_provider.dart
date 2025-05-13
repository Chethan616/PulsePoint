import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String THEME_KEY = 'theme_mode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  _loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(THEME_KEY) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(THEME_KEY, _isDarkMode);
    notifyListeners();
  }

  ThemeData get themeData {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  // Light theme definition - Warm orange/red tones
  ThemeData get _lightTheme {
    return ThemeData(
      primaryColor: Color(0xFFFF5F6D),
      scaffoldBackgroundColor: Color(0xFFFFF8F6),
      colorScheme: ColorScheme.light(
        primary: Color(0xFFFF5F6D),
        secondary: Color(0xFFFFC371),
        tertiary: Color(0xFFFF8068),
        surface: Colors.white,
        background: Color(0xFFFFF8F6),
        error: Color(0xFFE53935),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Color(0xFF333333),
        onBackground: Color(0xFF333333),
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFFFF5F6D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFF5F6D),
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFFFF5F6D),
          side: BorderSide(color: Color(0xFFFF5F6D)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFFFF5F6D),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: Color(0xFF333333),
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: Color(0xFF333333)),
        bodyMedium: TextStyle(color: Color(0xFF666666)),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
      ),
      iconTheme: IconThemeData(
        color: Color(0xFFFF5F6D),
        size: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFFF5F6D)),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  // Dark theme definition - Cool purple/blue tones
  ThemeData get _darkTheme {
    return ThemeData(
      primaryColor: Color(0xFF6A60F0),
      scaffoldBackgroundColor: Color(0xFF121212),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF6A60F0),
        secondary: Color(0xFF64DFDF),
        tertiary: Color(0xFF7F7FD5),
        surface: Color(0xFF1F1F1F),
        background: Color(0xFF121212),
        error: Color(0xFFCF6679),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.black,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF6A60F0),
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFF6A60F0),
          side: BorderSide(color: Color(0xFF6A60F0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFF6A60F0),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
      ),
      cardTheme: CardTheme(
        color: Color(0xFF1F1F1F),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: Color(0xFF6A60F0),
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: Color(0xFF1F1F1F),
        elevation: 2,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800,
        thickness: 1,
      ),
      iconTheme: IconThemeData(
        color: Color(0xFF6A60F0),
        size: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF6A60F0)),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}
