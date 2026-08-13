// lib/theme/app_theme.dart
// F3 Digital Weinke — high-contrast theme for 5:30 AM field use.
//
// Palette sourced directly from F3 Nation's own sites (codex.f3nation.com /
// f3nation.com — shadcn/ui tokens, extracted from their shipped CSS on
// 2026-07-31): background #1A1A1A / #FFFFFF, card matches background
// (separated by border only, same as their site), primary red #AA1008,
// neutral (not blue-tinted) grays for text.
//
// One deliberate deviation: `accent` here is #EA160B, not the literal
// #AA1008. Codex only ever uses their red as a button *fill* (white text on
// top), where #AA1008 has plenty of contrast. Weinke also uses `accent` as
// bare text/icon color directly on the background (nav bar, timer digits,
// phase labels) — #AA1008 on #1A1A1A measures ~2.3:1, well under WCAG's 3:1
// floor for UI text. #EA160B keeps the same hue/saturation (same brand red)
// at a lightness that clears ~3.8:1 on dark, ~4.6:1 on light, and ~4.6:1 for
// white-on-fill — legible in every context this token is actually used in.
//
// Previous palette (revert via `git checkout <prior-commit> -- lib/theme/app_theme.dart`
// if this doesn't land well):
//   dark:  background #242A2B, card #1E2123, elevated #2C3234, divider #383E40,
//          textPrimary #FFFFFF, textSecondary #B0B8BA, textMuted #6A7375,
//          accent #EE6059, accentDim #B84740
//   light: background #F2EFEC, card #FFFFFF, elevated #E8E5E2, divider #D0CDC9,
//          textPrimary #1A1A1A, textSecondary #555252, textMuted #8A8785
//
// Typography: maximum legibility at arm's length.  Boldest weights for
// exercise names.  Big tap targets (minimum 56 dp) for sweaty/gloved hands.

import 'package:flutter/material.dart';

class F3Colors {
  F3Colors._();

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color background    = Color(0xFF1A1A1A);
  // Codex uses card == background (border-only separation) — fine on a
  // desktop browser, but a 1px border on near-identical dark tones is easy
  // to lose in direct sunlight, which is exactly when this app gets used.
  // Nudged one step lighter so cards read even without the border catching
  // the light right.
  static const Color card          = Color(0xFF1E1E1E);
  static const Color elevated      = Color(0xFF2A2A2A);
  static const Color divider       = Color(0xFF333333);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF2F2F2);
  static const Color textSecondary = Color(0xFFB8B8B8);
  static const Color textMuted     = Color(0xFF808080);

  // ── Accent ────────────────────────────────────────────────────────────────
  static const Color accent        = Color(0xFFEA160B); // F3 Nation red, brightened for legibility — see file header
  static const Color accentDim     = Color(0xFFB01008);
  // Second hierarchy tier — accent red had been doing double duty as both
  // "this is the primary action" and "this is just a tinted icon/border,"
  // which flattened its own signal value. Reserve accent for genuinely
  // primary CTAs; use this muted bronze for secondary/utility actions
  // (e.g. an inline "ADD +" next to a section header) that still want some
  // color, just not competing with the real call to action on screen.
  static const Color accentSecondary = Color(0xFFC9A227);

  // ── Phase colours (segment bar + phase header) ────────────────────────────
  static const Color phaseDisclaimer = Color(0xFF7B8EAA); // steel blue
  static const Color phaseWarmup     = Color(0xFF4CAF50); // green
  static const Color phaseThang      = accent;
  static const Color phaseMary       = Color(0xFF9C6FE0); // purple
  static const Color phaseCOT        = Color(0xFFFFD54F); // gold

  // ── Category colours ─────────────────────────────────────────────────────
  static const Color catWarmup     = Color(0xFF4CAF50);
  static const Color catBodyweight = Color(0xFF5B9BD5);
  static const Color catCoupon     = Color(0xFFFF9800);
  static const Color catMary       = Color(0xFF9C6FE0);

  // ── Intensity ─────────────────────────────────────────────────────────────
  static const Color intBeginner     = Color(0xFF4CAF50);
  static const Color intIntermediate = Color(0xFFFFB300);
  static const Color intAdvanced     = accent;

  static Color forCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'warmup':     return catWarmup;
      case 'coupon':     return catCoupon;
      case 'mary':       return catMary;
      default:           return catBodyweight;
    }
  }

  static Color forIntensity(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'beginner':     return intBeginner;
      case 'advanced':     return intAdvanced;
      default:             return intIntermediate;
    }
  }
}

class F3LightColors {
  F3LightColors._();
  static const Color background    = Color(0xFFFFFFFF);
  // Unlike dark mode, a light border on white doesn't get lost in direct
  // sun, so card == background (matching codex.f3nation.com) is kept as-is.
  static const Color card          = Color(0xFFFFFFFF);
  static const Color elevated      = Color(0xFFEFEFEF);
  static const Color divider       = Color(0xFFE5E5E5);
  static const Color textPrimary   = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF595959);
  static const Color textMuted     = Color(0xFF737373);
}

// BuildContext extension — use these instead of raw F3Colors in build methods
// so the correct palette is returned for the active theme (dark or light).
extension F3ThemeX on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;
  Color get f3bg          => _isDark ? F3Colors.background    : F3LightColors.background;
  Color get f3card        => _isDark ? F3Colors.card          : F3LightColors.card;
  Color get f3elevated    => _isDark ? F3Colors.elevated      : F3LightColors.elevated;
  Color get f3divider     => _isDark ? F3Colors.divider       : F3LightColors.divider;
  Color get f3textPrimary   => _isDark ? F3Colors.textPrimary   : F3LightColors.textPrimary;
  Color get f3textSecondary => _isDark ? F3Colors.textSecondary : F3LightColors.textSecondary;
  Color get f3textMuted     => _isDark ? F3Colors.textMuted     : F3LightColors.textMuted;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: F3LightColors.background,
      colorScheme: const ColorScheme.light(
        surface: F3LightColors.card,
        primary: F3Colors.accent,
        onPrimary: Colors.white,
        secondary: F3Colors.accent,
        onSecondary: Colors.white,
        onSurface: F3LightColors.textPrimary,
        surfaceContainerHighest: F3LightColors.elevated,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: F3LightColors.background,
        foregroundColor: F3LightColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: F3LightColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: F3LightColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: F3LightColors.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: F3Colors.accent.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: F3Colors.accent, size: 26);
          }
          return const IconThemeData(color: F3LightColors.textSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: F3Colors.accent, fontWeight: FontWeight.w700, fontSize: 12);
          }
          return const TextStyle(color: F3LightColors.textSecondary, fontSize: 12);
        }),
      ),
      cardTheme: const CardThemeData(
        color: F3LightColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: F3LightColors.divider),
        ),
        margin: EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: F3Colors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 64),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: F3Colors.accent,
          minimumSize: const Size(64, 56),
          side: const BorderSide(color: F3Colors.accent, width: 1.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: F3Colors.accent,
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: F3LightColors.elevated,
        labelStyle: const TextStyle(color: F3LightColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: F3LightColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 48, height: 1.1),
        displayMedium: TextStyle(color: F3LightColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 36, height: 1.1),
        displaySmall: TextStyle(color: F3Colors.accent, fontWeight: FontWeight.w800, fontSize: 64, letterSpacing: 2, fontFeatures: [FontFeature.tabularFigures()]),
        titleLarge: TextStyle(color: F3LightColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 22),
        titleMedium: TextStyle(color: F3LightColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
        titleSmall: TextStyle(color: F3LightColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.5),
        bodyLarge: TextStyle(color: F3LightColors.textPrimary, fontSize: 16, height: 1.55),
        bodyMedium: TextStyle(color: F3LightColors.textSecondary, fontSize: 14, height: 1.45),
        bodySmall: TextStyle(color: F3LightColors.textMuted, fontSize: 12),
        labelLarge: TextStyle(color: F3LightColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3),
        labelSmall: TextStyle(color: F3LightColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
      ),
      dividerTheme: const DividerThemeData(color: F3LightColors.divider, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: F3LightColors.card,
        hintStyle: const TextStyle(color: F3LightColors.textMuted),
        prefixIconColor: F3LightColors.textSecondary,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: F3LightColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: F3LightColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: F3Colors.accent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: F3LightColors.elevated,
        contentTextStyle: const TextStyle(color: F3LightColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? F3Colors.accent : F3LightColors.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? F3Colors.accent.withValues(alpha: 0.4)
                : F3LightColors.divider),
      ),
      // Every bare CircularProgressIndicator() across the app — a dozen+
      // call sites, most without an explicit color — was falling back to
      // Material's default indicator color instead of F3 red, reading as
      // an unstyled/generic loading state rather than an intentional one.
      // One theme property fixes every call site at once.
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: F3Colors.accent,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: F3Colors.background,
      colorScheme: const ColorScheme.dark(
        surface: F3Colors.card,
        primary: F3Colors.accent,
        onPrimary: Colors.white,
        secondary: F3Colors.accent,
        onSecondary: Colors.white,
        onSurface: F3Colors.textPrimary,
        surfaceContainerHighest: F3Colors.elevated,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: F3Colors.background,
        foregroundColor: F3Colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: F3Colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: F3Colors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: F3Colors.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: F3Colors.accent.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: F3Colors.accent, size: 26);
          }
          return const IconThemeData(color: F3Colors.textSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: F3Colors.accent, fontWeight: FontWeight.w700, fontSize: 12);
          }
          return const TextStyle(color: F3Colors.textSecondary, fontSize: 12);
        }),
      ),
      cardTheme: const CardThemeData(
        color: F3Colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: F3Colors.divider),
        ),
        margin: EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: F3Colors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 64), // big tap target
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: F3Colors.accent,
          minimumSize: const Size(64, 56),
          side: const BorderSide(color: F3Colors.accent, width: 1.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: F3Colors.accent,
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: F3Colors.elevated,
        labelStyle: const TextStyle(
            color: F3Colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textTheme: const TextTheme(
        // Used for huge exercise names during live workout
        displayLarge: TextStyle(
          color: F3Colors.textPrimary, fontWeight: FontWeight.w900, fontSize: 48,
          height: 1.1, letterSpacing: -0.5),
        displayMedium: TextStyle(
          color: F3Colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 36,
          height: 1.1),
        // Timer countdown digits
        displaySmall: TextStyle(
          color: F3Colors.accent, fontWeight: FontWeight.w800, fontSize: 64,
          letterSpacing: 2,
          fontFeatures: [FontFeature.tabularFigures()]),
        titleLarge: TextStyle(
          color: F3Colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 22),
        titleMedium: TextStyle(
          color: F3Colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
        titleSmall: TextStyle(
          color: F3Colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14,
          letterSpacing: 0.5),
        bodyLarge: TextStyle(
          color: F3Colors.textPrimary, fontSize: 16, height: 1.55),
        bodyMedium: TextStyle(
          color: F3Colors.textSecondary, fontSize: 14, height: 1.45),
        bodySmall: TextStyle(
          color: F3Colors.textMuted, fontSize: 12),
        labelLarge: TextStyle(
          color: F3Colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15,
          letterSpacing: 0.3),
        labelSmall: TextStyle(
          color: F3Colors.textMuted, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 1.5),
      ),
      dividerTheme: const DividerThemeData(
          color: F3Colors.divider, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: F3Colors.card,
        hintStyle: const TextStyle(color: F3Colors.textMuted),
        prefixIconColor: F3Colors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: F3Colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: F3Colors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: F3Colors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: F3Colors.elevated,
        contentTextStyle: const TextStyle(color: F3Colors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? F3Colors.accent : F3Colors.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? F3Colors.accent.withValues(alpha: 0.4)
                : F3Colors.divider),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: F3Colors.accent,
      ),
    );
  }
}
