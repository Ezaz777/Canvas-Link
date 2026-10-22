import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pinterest Design System Theme tokens matching DESIGN.md
/// Supports Light Mode and Dark Mode with system preference detection.
class PinterestTheme {
  // Brand & Accent (Identical across themes)
  static const Color primary = Color(0xFFE60023); // Pinterest Red
  static const Color primaryPressed = Color(0xFFCC001F);

  // Surfaces & Backgrounds (Light Mode)
  static const Color canvas = Color(0xFFFFFFFF); // True White
  static const Color surfaceSoft = Color(0xFFFBFBF9); // Soft warm-cream
  static const Color surfaceCard = Color(0xFFF6F6F3); // Warm-cream card fill
  static const Color surfaceDark = Color(0xFF262622); // Dark strip surface
  static const Color secondaryBg = Color(0xFFE5E5E0); // Gray-cream secondary
  static const Color secondaryPressed = Color(0xFFC8C8C1);

  // Dividers & Hairlines (Light Mode)
  static const Color hairline = Color(0xFFDADAD3);
  static const Color hairlineSoft = Color(0xFFE5E5E0);

  // Text & Ink (Light Mode)
  static const Color ink = Color(0xFF000000);
  static const Color inkSoft = Color(0xFF211922);
  static const Color body = Color(0xFF33332E);
  static const Color charcoal = Color(0xFF262622);
  static const Color mute = Color(0xFF62625B);
  static const Color ash = Color(0xFF91918C);
  static const Color stone = Color(0xFFC8C8C1);

  // Surfaces & Backgrounds (Dark Mode - per DESIGN.md)
  static const Color canvasDark = Color(0xFF121212); // Deep dark canvas
  static const Color surfaceSoftDark = Color(0xFF181816); // Charcoal soft surface
  static const Color surfaceCardDark = Color(0xFF262622); // surface-dark from DESIGN.md
  static const Color surfaceElevatedDark = Color(0xFF2E2E29);
  static const Color secondaryBgDark = Color(0xFF33332E); // Deep gray secondary button fill
  static const Color secondaryPressedDark = Color(0xFF45453E);

  // Dividers & Hairlines (Dark Mode)
  static const Color hairlineDark = Color(0xFF383832);
  static const Color hairlineSoftDark = Color(0xFF2C2C26);

  // Text & Ink (Dark Mode)
  static const Color inkDark = Color(0xFFFFFFFF); // on-dark from DESIGN.md
  static const Color bodyDark = Color(0xFFE5E5E0);
  static const Color muteDark = Color(0xB3FFFFFF); // on-dark-mute: 70% white
  static const Color ashDark = Color(0xFF8E8E87);
  static const Color stoneDark = Color(0xFF4A4A44);

  // Semantics
  static const Color focusOuter = Color(0xFF435EE5);
  static const Color successDeep = Color(0xFF103C25);
  static const Color successPale = Color(0xFFC7F0DA);
  static const Color successBright = Color(0xFF10B981);
  static const Color error = Color(0xFF9E0A0A);
  static const Color errorDeep = Color(0xFFCC001F);

  // Radii per DESIGN.md
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0; // Universal Pinterest component radius
  static const double radiusLg = 32.0; // Large cards & Modals
  static const double radiusFull = 9999.0; // Chips & Pills

  // Spacing
  static const double spaceSm = 8.0; // Standard tight gutter
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double spaceXxl = 32.0;

  // Context-aware Theme Helpers
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getSurfaceSoft(BuildContext context) =>
      isDark(context) ? surfaceSoftDark : surfaceSoft;

  static Color getCanvas(BuildContext context) =>
      isDark(context) ? canvasDark : canvas;

  static Color getSurfaceCard(BuildContext context) =>
      isDark(context) ? surfaceCardDark : surfaceCard;

  static Color getSurfaceElevated(BuildContext context) =>
      isDark(context) ? surfaceElevatedDark : canvas;

  static Color getInk(BuildContext context) =>
      isDark(context) ? inkDark : ink;

  static Color getBody(BuildContext context) =>
      isDark(context) ? bodyDark : body;

  static Color getMute(BuildContext context) =>
      isDark(context) ? muteDark : mute;

  static Color getAsh(BuildContext context) =>
      isDark(context) ? ashDark : ash;

  static Color getHairline(BuildContext context) =>
      isDark(context) ? hairlineDark : hairline;

  static Color getHairlineSoft(BuildContext context) =>
      isDark(context) ? hairlineSoftDark : hairlineSoft;

  static Color getSecondaryBg(BuildContext context) =>
      isDark(context) ? secondaryBgDark : secondaryBg;

  // Primary Button Style per DESIGN.md (Height 40-44, rounded 16px or custom pill, Pinterest Red)
  static ButtonStyle primaryButtonStyle({
    BuildContext? context,
    double height = 44,
    double? radius,
    EdgeInsetsGeometry? padding,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      minimumSize: Size(0, height),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius ?? radiusMd),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // Secondary Button Style per DESIGN.md (Theme-adaptive fill, rounded 16px or custom pill)
  static ButtonStyle secondaryButtonStyle({
    BuildContext? context,
    double height = 44,
    double? radius,
    EdgeInsetsGeometry? padding,
  }) {
    final dark = context != null && isDark(context);
    return ElevatedButton.styleFrom(
      backgroundColor: dark ? secondaryBgDark : secondaryBg,
      foregroundColor: dark ? inkDark : ink,
      elevation: 0,
      shadowColor: Colors.transparent,
      minimumSize: Size(0, height),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius ?? radiusMd),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // Pill on image button / Chip style
  static BoxDecoration pillOnImageDecoration([BuildContext? context]) {
    final dark = context != null && isDark(context);
    return BoxDecoration(
      color: dark ? const Color(0xE6262622) : const Color(0xE6FFFFFF),
      borderRadius: BorderRadius.circular(radiusFull),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(dark ? 0.35 : 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Card Decoration (Theme-adaptive warm-cream or dark charcoal, 16px radius)
  static BoxDecoration cardDecoration({
    BuildContext? context,
    bool soft = false,
    bool border = true,
  }) {
    final dark = context != null && isDark(context);
    final bgColor = soft
        ? (dark ? surfaceCardDark : surfaceCard)
        : (dark ? surfaceElevatedDark : canvas);
    final borderColor = dark ? hairlineSoftDark : hairlineSoft;

    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radiusMd),
      border: border ? Border.all(color: borderColor, width: 1) : null,
    );
  }

  // Soft ambient overlay shadow for buttons, pills and floating dialogs
  static List<BoxShadow> get overlayShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Large Modal Decoration (Theme-adaptive, 32px radius, soft ambient shadow)
  static BoxDecoration modalDecoration([BuildContext? context]) {
    final dark = context != null && isDark(context);
    return BoxDecoration(
      color: dark ? surfaceCardDark : canvas,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(radiusLg)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(dark ? 0.5 : 0.15),
          blurRadius: 32,
          offset: const Offset(0, -8),
        ),
      ],
    );
  }

  // Complete Material 3 Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        surface: surfaceSoft,
      ),
      scaffoldBackgroundColor: surfaceSoft,
      canvasColor: canvas,
      cardColor: surfaceCard,
      dividerColor: hairline,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: body,
        displayColor: ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceSoft,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle(),
      ),
    );
  }

  // Complete Material 3 Dark Theme matching DESIGN.md
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        surface: surfaceSoftDark,
      ),
      scaffoldBackgroundColor: surfaceSoftDark,
      canvasColor: canvasDark,
      cardColor: surfaceCardDark,
      dividerColor: hairlineDark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: bodyDark,
        displayColor: inkDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceSoftDark,
        foregroundColor: inkDark,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          color: inkDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle(),
      ),
    );
  }
}
