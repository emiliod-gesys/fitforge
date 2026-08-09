import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_accent.dart';
import 'app_colors.dart';
import 'app_tokens.dart';

class AppTheme {
  /// @Deprecated: prefer [AppTokens.radiusMd]
  static const borderRadius = AppTokens.radiusMd;

  static ThemeData dark({AppAccent accent = AppAccent.defaultAccent}) {
    final palette = FitForgeAccent.fromAccent(accent);
    final primary = palette.accentColor;
    final secondary = palette.accentDark;

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.black,
        secondary: secondary,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      cardColor: AppColors.card,
      dividerColor: AppColors.border.withValues(alpha: 0.7),
      splashColor: primary.withValues(alpha: 0.12),
      highlightColor: primary.withValues(alpha: 0.08),
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primary : AppColors.textMuted,
            size: 22,
          );
        }),
        height: AppTokens.navBarHeight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusMd),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusLg,
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.75)),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardElevated,
        shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusXl),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardElevated,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTokens.radiusXl)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardElevated,
        labelStyle:
            GoogleFonts.montserrat(color: AppColors.textMuted, fontSize: 14),
        hintStyle: GoogleFonts.montserrat(
            color: AppColors.textMuted.withValues(alpha: 0.6)),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusMd,
          borderSide:
              BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusMd,
          borderSide: BorderSide(color: primary, width: AppTokens.borderAccent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppColors.slate,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          minimumSize: const Size(0, AppTokens.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusMd),
          textStyle:
              GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(0, AppTokens.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusMd),
          textStyle:
              GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(0, AppTokens.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusMd),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardElevated,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle:
            GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusSm)),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle:
            GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle:
            GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14),
        labelColor: primary,
        unselectedLabelColor: AppColors.textMuted,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primary, width: 2.5),
          insets: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardElevated,
        contentTextStyle: GoogleFonts.montserrat(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusMd),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppTokens.space8),
        shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusMd),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.35);
          }
          return AppColors.slate;
        }),
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
