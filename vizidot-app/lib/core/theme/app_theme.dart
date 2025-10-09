import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Light
  static const Color lightPrimary = Color(0xFF4F46E5);
  static const Color lightSecondary = Color(0xFF06B6D4);
  static const Color lightAccent = Color(0xFF22C55E);
  static const Color lightBackground = Color(0xFFEFF3F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightError = Color(0xFFEF4444);

  // Dark
  static const Color darkPrimary = Color(0xFF8B5CF6);
  static const Color darkSecondary = Color(0xFF22D3EE);
  static const Color darkAccent = Color(0xFF34D399);
  static const Color darkBackground = Color(0xFF0B0B12);
  static const Color darkSurface = Color(0xFF12121A);
  static const Color darkError = Color(0xFFF87171);
}

class AppTextStyles {
  static TextTheme textTheme(ColorScheme colors) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.onBackground,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.onBackground,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.onBackground,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.onBackground.withOpacity(0.9),
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        height: 1.4,
        color: colors.onBackground.withOpacity(0.9),
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        height: 1.45,
        color: colors.onBackground.withOpacity(0.8),
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: colors.onBackground.withOpacity(0.9),
      ),
    );
  }
}

class AppTheme {
  static ThemeData _baseTheme({required bool isDark}) {
    final colorScheme = isDark
        ? ColorScheme(
            brightness: Brightness.dark,
            primary: AppColors.darkPrimary,
            onPrimary: Colors.white,
            secondary: AppColors.darkSecondary,
            onSecondary: Colors.white,
            error: AppColors.darkError,
            onError: Colors.white,
            background: AppColors.darkBackground,
            onBackground: const Color(0xFFE5E7EB),
            surface: AppColors.darkSurface,
            onSurface: const Color(0xFFE5E7EB),
          )
        : ColorScheme(
            brightness: Brightness.light,
            primary: AppColors.lightPrimary,
            onPrimary: Colors.white,
            secondary: AppColors.lightSecondary,
            onSecondary: Colors.white,
            error: AppColors.lightError,
            onError: Colors.white,
            background: AppColors.lightBackground,
            onBackground: const Color(0xFF0F172A),
            surface: AppColors.lightSurface,
            onSurface: const Color(0xFF0F172A),
          );

    final textTheme = AppTextStyles.textTheme(colorScheme);

    final appBarTheme = AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    final buttonTheme = FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: buttonShape,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );

    final outlinedButtonTheme = OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: buttonShape,
        side: BorderSide(color: colorScheme.primary, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        foregroundColor: colorScheme.primary,
      ),
    );

    final textButtonTheme = TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
      ),
    );

    final iconTheme = IconThemeData(
      color: colorScheme.onBackground.withOpacity(0.9),
    );

    final bottomNav = BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      elevation: 8,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    );

    final searchBarTheme = SearchBarThemeData(
      backgroundColor: WidgetStatePropertyAll(
        isDark ? const Color(0xFF161622) : Colors.white,
      ),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      hintStyle: WidgetStatePropertyAll(
        textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        textTheme.bodyMedium,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: appBarTheme,
      filledButtonTheme: buttonTheme,
      outlinedButtonTheme: outlinedButtonTheme,
      textButtonTheme: textButtonTheme,
      iconTheme: iconTheme,
      scaffoldBackgroundColor: colorScheme.background,
      bottomNavigationBarTheme: bottomNav,
      searchBarTheme: searchBarTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        margin: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF161622) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }

  static ThemeData get light => _baseTheme(isDark: false);
  static ThemeData get dark => _baseTheme(isDark: true);
}


