import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _moss = Color(0xFF2A6A59);
  static const Color _gold = Color(0xFFD89B3B);
  static const Color _cream = Color(0xFFF7F1E4);
  static const Color _ink = Color(0xFF1F2B28);

  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _moss,
          brightness: Brightness.light,
        ).copyWith(
          primary: _moss,
          secondary: _gold,
          tertiary: const Color(0xFF6D8E32),
          surface: Colors.white,
          surfaceContainerHighest: const Color(0xFFE8E2D4),
          onSurface: _ink,
        );

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _cream,
    );

    return baseTheme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: _cream,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: baseTheme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.surfaceContainerHighest),
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
    );
  }
}
