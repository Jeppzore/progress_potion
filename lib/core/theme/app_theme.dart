import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _cobalt = Color(0xFF2E4DA7);
  static const Color _coral = Color(0xFFE06B4C);
  static const Color _sage = Color(0xFF4F8F74);
  static const Color _linen = Color(0xFFF6F1E8);
  static const Color _ink = Color(0xFF1B2436);

  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _cobalt,
          brightness: Brightness.light,
        ).copyWith(
          primary: _cobalt,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFDDE5FF),
          onPrimaryContainer: _ink,
          secondary: _coral,
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFFCE1D7),
          onSecondaryContainer: _ink,
          tertiary: _sage,
          onTertiary: Colors.white,
          tertiaryContainer: const Color(0xFFD8EBDD),
          onTertiaryContainer: _ink,
          surface: Colors.white,
          surfaceContainerLowest: const Color(0xFFFFFBF5),
          surfaceContainerLow: const Color(0xFFFBF6EE),
          surfaceContainerHighest: const Color(0xFFEAE3D8),
          shadow: _ink,
          onSurface: _ink,
          onSurfaceVariant: const Color(0xFF5E6677),
          outline: const Color(0xFFD5CFC4),
        );

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _linen,
    );

    return baseTheme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: _linen,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: baseTheme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.06)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          textStyle: baseTheme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: colorScheme.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return baseTheme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        backgroundColor: colorScheme.secondaryContainer,
        side: BorderSide.none,
        labelStyle: baseTheme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: baseTheme.textTheme.copyWith(
        headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
        bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.45,
        ),
      ),
    );
  }
}
