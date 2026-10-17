import 'package:flutter/material.dart';

/// Token warna — sama dengan DESIGN.md dan aplikasi web Laravel.
class AppColors {
  static const primary = Color(0xFF4F46E5);
  static const primaryPressed = Color(0xFF4338CA);
  static const primarySoft = Color(0xFFEEF2FF);

  static const ink = Color(0xFF0F172A);
  static const inkMuted = Color(0xFF475569);
  static const muted = Color(0xFF64748B);

  static const border = Color(0xFFE2E8F0);
  static const borderStrong = Color(0xFFCBD5E1);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFF8FAFC);
  static const canvas = Color(0xFFF1F5F9);
  static const shell = Color(0xFF0F172A);

  static const success = Color(0xFF059669);
  static const successSoft = Color(0xFFD1FAE5);
  static const warning = Color(0xFFB45309);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFBE123C);
  static const dangerSoft = Color(0xFFFFE4E6);
}

/// Instrument Sans adalah variable font, jadi berat huruf diatur lewat
/// `fontVariations` (bukan hanya `fontWeight`).
TextStyle appText({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color? color,
  double? height,
  double? letterSpacing,
  TextDecoration? decoration,
}) {
  return TextStyle(
    fontFamily: 'InstrumentSans',
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    color: color ?? AppColors.ink,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );
}

/// Gaya label kecil huruf besar (dipakai di atas nilai / judul kolom).
TextStyle labelText({Color? color}) => appText(
      size: 11,
      weight: FontWeight.w700,
      letterSpacing: 0.6,
      color: color ?? AppColors.muted,
    );

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: 'InstrumentSans',
    );

    return base.copyWith(
      textTheme: TextTheme(
        displaySmall: appText(size: 28, weight: FontWeight.w800, letterSpacing: -0.6),
        titleLarge: appText(size: 20, weight: FontWeight.w700, letterSpacing: -0.2),
        titleMedium: appText(size: 16, weight: FontWeight.w700),
        titleSmall: appText(size: 15, weight: FontWeight.w600),
        bodyLarge: appText(size: 15),
        bodyMedium: appText(size: 14),
        bodySmall: appText(size: 12, color: AppColors.muted),
        labelLarge: appText(size: 14, weight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: appText(size: 16, weight: FontWeight.w700),
        iconTheme: const IconThemeData(color: AppColors.inkMuted, size: 20),
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          textStyle: appText(size: 14, weight: FontWeight.w700, color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(44),
          side: const BorderSide(color: AppColors.border),
          textStyle: appText(size: 14, weight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: appText(size: 14, color: AppColors.borderStrong),
        labelStyle: appText(size: 13, color: AppColors.inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: appText(size: 13, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        surfaceTintColor: Colors.transparent,
        height: 64,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => appText(
            size: 10,
            weight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 20,
            color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.muted,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
    );
  }
}
