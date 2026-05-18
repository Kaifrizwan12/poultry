import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color sidebarBg = Color(0xFF0F1117);
  static const Color sidebarText = Color(0xB3FFFFFF);
  static const Color sidebarActiveText = textOnDark;
  static const Color drawerHeaderBg = sidebarBg;
  static const double sidebarWidthExpanded = 240;
  static const double sidebarWidthCollapsed = 60;
  static const double inputRadius = 10;

  // ── Form field standard widths ─────────────────────────────────────────────
  /// Short: dates, short numbers, codes
  static const double fieldS = 150.0;
  /// Medium: names, dropdowns, IDs
  static const double fieldM = 200.0;
  /// Large: narration, long text
  static const double fieldL = 260.0;

  // ── DataTable density ──────────────────────────────────────────────────────
  static const double tableColSpacing  = 16.0;
  static const double tableHMargin     = 12.0;
  static const double tableRowMin      = 30.0;
  static const double tableRowMax      = 36.0;
  static const double tableHeadingH    = 36.0;
  static const double dialogDesktopWidth = 1180.0;
  static const double dialogDesktopHeight = 760.0;

  static const Color clayBg = Color(0xFFF8F2EA);
  static const Color claySurface = Color(0xFFF0E4D2);
  static const Color claySurface2 = Color(0xFFE6D4BC);
  static const Color clayBorder = Color(0xFFD8BFA6);
  static const Color clayBorder2 = Color(0xFFC9A888);

  static const Color terra50 = Color(0xFFFDF1EC);
  static const Color terra100 = Color(0xFFF9D9CC);
  static const Color terra200 = Color(0xFFF3B89F);
  static const Color terra400 = Color(0xFFD4856A);
  static const Color terra600 = Color(0xFFB5614A);
  static const Color terra800 = Color(0xFF7A3A28);
  static const Color terra900 = Color(0xFF4F2118);

  static const Color sand100 = Color(0xFFF8EDD8);
  static const Color sand200 = Color(0xFFF0D9B5);
  static const Color sand400 = Color(0xFFE0B88A);
  static const Color sand600 = Color(0xFFC49660);
  static const Color sand800 = Color(0xFF8A6030);

  static const Color textPrimary = Color(0xFF5C3D2E);
  static const Color textSecondary = Color(0xFF9C7B6E);
  static const Color textTertiary = Color(0xFFC4A898);

  static const Color successBg = Color(0xFFEFF6EE);
  static const Color successText = Color(0xFF3A6B35);
  static const Color warningBg = Color(0xFFFBF3E6);
  static const Color warningText = Color(0xFF8A5A1A);
  static const Color dangerBg = Color(0xFFFAF0EE);
  static const Color dangerText = Color(0xFF8A3828);
  static const Color pageBg = Color(0xFFF5F6FA);
  static const Color pageDivider = Color(0xFFE7E9F0);
  static const Color softBorder = Color(0xFFD9DEE8);
  static const Color shadowColor = Color(0x12000000);
  static const Color handleColor = Color(0xFFD3D8E3);

  static Color get sidebarActive => terra400.withValues(alpha: 0.15);
  static Color get listTileDivider => softBorder;
  static Color get inputBorderColor => softBorder;
  static Color get inputFocusBorderColor => terra400;
  static EdgeInsets get cardPadding => const EdgeInsets.all(20);
  static EdgeInsets get tilePadding =>
      const EdgeInsets.symmetric(horizontal: 18, vertical: 8);
  static BorderRadius get cardRadius => BorderRadius.circular(12);
  static BorderRadius get dialogRadius => BorderRadius.circular(16);
  static EdgeInsets pagePadding(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return EdgeInsets.symmetric(
      horizontal: isMobile ? 12 : 24,
      vertical: isMobile ? 12 : 20,
    );
  }

  static BoxDecoration get cardDecor => BoxDecoration(
        color: surfaceWhite,
        borderRadius: cardRadius,
        boxShadow: [
          const BoxShadow(
            color: shadowColor,
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      );

  static InputDecoration inputDecoration(
    String? label, {
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool dense = true,
    bool readOnly = false,
  }) {
    final hasLabel = label != null && label.isNotEmpty;
    return InputDecoration(
      // Label always sits above the field (never floats from inside).
      // hintText shows inside when the field is empty — same pattern as
      // the Settings module's _LabeledField + hintText approach.
      labelText: hasLabel ? label : null,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: hintText ?? (hasLabel ? label : null),
      hintStyle: const TextStyle(
        color: textTertiary,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        color: textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: dense,
      fillColor: readOnly ? clayBg : surfaceWhite,
    );
  }

  static TextStyle navLabel([Color? color]) => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: terra400,
      brightness: Brightness.light,
      primary: terra400,
      surface: claySurface,
      error: dangerText,
    ).copyWith(
      secondary: sand400,
      tertiary: sand600,
      onPrimary: textOnDark,
      onSecondary: textOnDark,
      onSurface: textPrimary,
      outline: clayBorder,
      surfaceContainerHighest: claySurface2,
      surfaceContainerHigh: claySurface,
      surfaceContainer: clayBg,
    );

    final baseText = GoogleFonts.dmSansTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: pageBg,
      textTheme: baseText.copyWith(
        headlineLarge: GoogleFonts.dmSans(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.1,
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.12,
        ),
        headlineSmall: GoogleFonts.dmSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.55,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.55,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: pageBg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceWhite,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        hintStyle: GoogleFonts.dmSans(
          color: textTertiary,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.dmSans(
          color: textSecondary,
          fontWeight: FontWeight.w600,
        ),
        // When floatingLabelBehavior.always is used, this style applies
        // to the label shown above the field — matches _LabeledField in settings.
        floatingLabelStyle: GoogleFonts.dmSans(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        helperStyle: GoogleFonts.dmSans(
          color: textSecondary,
          fontSize: 12,
        ),
        errorStyle: GoogleFonts.dmSans(
          color: dangerText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _inputBorder(inputBorderColor, width: 1),
        enabledBorder: _inputBorder(inputBorderColor, width: 1),
        focusedBorder: _inputBorder(inputFocusBorderColor, width: 1.4),
        errorBorder: _inputBorder(dangerText, width: 1.5),
        focusedErrorBorder: _inputBorder(dangerText, width: 1.5),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      // Zero-width scrollbars prevent horizontal CLS when a vertical scrollbar
      // would otherwise steal layout space and shift all content left.
      scrollbarTheme: const ScrollbarThemeData(
        thickness: WidgetStatePropertyAll(0),
        thumbVisibility: WidgetStatePropertyAll(false),
        trackVisibility: WidgetStatePropertyAll(false),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.dmSans(
          color: surfaceWhite,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        side: const BorderSide(color: clayBorder2, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return terra400;
          }
          return clayBg;
        }),
        checkColor: WidgetStateProperty.all(surfaceWhite),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          textStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: terra400,
          foregroundColor: surfaceWhite,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(inputRadius),
          ),
          textStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: inputBorderColor),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(inputRadius),
          ),
          textStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: terra600,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: dialogRadius,
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(inputRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
