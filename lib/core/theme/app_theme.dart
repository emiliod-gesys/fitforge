import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static const borderRadius = 8.0;

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        onPrimary: Colors.black,
        secondary: AppColors.goldDark,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      cardColor: AppColors.card,
      dividerColor: AppColors.border,
      splashColor: AppColors.gold.withValues(alpha: 0.12),
      highlightColor: AppColors.gold.withValues(alpha: 0.08),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.gold.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.gold : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.gold : AppColors.textMuted,
            size: 22,
          );
        }),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardElevated,
        labelStyle: GoogleFonts.montserrat(color: AppColors.textMuted, fontSize: 14),
        hintStyle: GoogleFonts.montserrat(color: AppColors.textMuted.withValues(alpha: 0.6)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppColors.slate,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardElevated,
        selectedColor: AppColors.gold.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.montserrat(fontSize: 13),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardElevated,
        contentTextStyle: GoogleFonts.montserrat(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
        behavior: SnackBarBehavior.floating,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.montserratTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }
}
