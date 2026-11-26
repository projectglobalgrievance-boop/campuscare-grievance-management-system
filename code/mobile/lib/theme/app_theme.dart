import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

abstract final class AppTheme {
  static TextTheme _text(Color body, Color soft) =>
      GoogleFonts.manropeTextTheme().copyWith(
        displaySmall: GoogleFonts.manrope(
            fontSize: 32, fontWeight: FontWeight.w800, color: body, height: 1.15),
        headlineMedium: GoogleFonts.manrope(
            fontSize: 24, fontWeight: FontWeight.w800, color: body, height: 1.2),
        titleLarge: GoogleFonts.manrope(
            fontSize: 19, fontWeight: FontWeight.w700, color: body),
        titleMedium: GoogleFonts.manrope(
            fontSize: 16, fontWeight: FontWeight.w700, color: body),
        titleSmall: GoogleFonts.manrope(
            fontSize: 14, fontWeight: FontWeight.w700, color: body),
        bodyLarge: GoogleFonts.manrope(fontSize: 16, color: body, height: 1.5),
        bodyMedium: GoogleFonts.manrope(fontSize: 14, color: body, height: 1.5),
        bodySmall: GoogleFonts.manrope(fontSize: 12.5, color: soft, height: 1.4),
        labelLarge: GoogleFonts.manrope(
            fontSize: 15, fontWeight: FontWeight.w700, color: body),
        labelMedium: GoogleFonts.manrope(
            fontSize: 12, fontWeight: FontWeight.w700, color: soft,
            letterSpacing: 0.4),
      );

  static ThemeData light() => _base(
        brightness: Brightness.light,
        surface: BrandColors.surfaceLight,
        card: BrandColors.cardLight,
        border: BrandColors.borderLight,
        text: BrandColors.ink,
        textSoft: BrandColors.inkSoft,
        primary: BrandColors.primary,
        primaryContainer: BrandColors.primaryContainer,
        onPrimaryContainer: BrandColors.primaryDark,
      );

  static ThemeData dark() => _base(
        brightness: Brightness.dark,
        surface: BrandColors.surfaceDark,
        card: BrandColors.cardDark,
        border: BrandColors.borderDark,
        text: BrandColors.textDark,
        textSoft: BrandColors.textSoftDark,
        primary: BrandColors.primaryLight,
        primaryContainer: BrandColors.primaryContainerDark,
        onPrimaryContainer: BrandColors.primaryContainer,
      );

  static ThemeData _base({
    required Brightness brightness,
    required Color surface,
    required Color card,
    required Color border,
    required Color text,
    required Color textSoft,
    required Color primary,
    required Color primaryContainer,
    required Color onPrimaryContainer,
  }) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isLight ? Colors.white : BrandColors.ink,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: BrandColors.accent,
      onSecondary: BrandColors.onAccent,
      secondaryContainer: BrandColors.accentContainer,
      onSecondaryContainer: BrandColors.onAccent,
      error: isLight ? BrandColors.danger : BrandColors.dangerDark,
      onError: isLight ? Colors.white : BrandColors.ink,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: card,
      outline: border,
      outlineVariant: border,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: isLight ? BrandColors.ink : BrandColors.surfaceLight,
      onInverseSurface: isLight ? Colors.white : BrandColors.ink,
      inversePrimary: isLight ? BrandColors.primaryLight : BrandColors.primary,
      tertiary: BrandColors.info,
      onTertiary: Colors.white,
    );

    final textTheme = _text(text, textSoft);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle:
            isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.md),
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Corners.md)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Corners.md)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: Space.md, vertical: Space.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.md),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.md),
          borderSide: BorderSide(color: scheme.error),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textSoft),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        side: BorderSide(color: border),
        labelStyle: textTheme.labelMedium?.copyWith(color: text),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Corners.pill)),
        padding: const EdgeInsets.symmetric(
            horizontal: Space.sm + 2, vertical: Space.xs + 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: primaryContainer,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? BrandColors.ink : BrandColors.cardDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
            color: isLight ? Colors.white : BrandColors.textDark),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Corners.sm)),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Corners.lg)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(Corners.lg))),
      ),
    );
  }
}
