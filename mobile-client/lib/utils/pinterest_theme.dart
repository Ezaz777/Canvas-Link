import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pinterest Design System Theme tokens matching DESIGN.md
class PinterestTheme {
  // Brand & Accent
  static const Color primary = Color(0xFFE60023); // Pinterest Red
  static const Color primaryPressed = Color(0xFFCC001F);

  // Surfaces & Backgrounds
  static const Color canvas = Color(0xFFFFFFFF); // True White
  static const Color surfaceSoft = Color(0xFFFBFBF9); // Soft warm-cream
  static const Color surfaceCard = Color(0xFFF6F6F3); // Warm-cream card fill
  static const Color surfaceDark = Color(0xFF262622); // Dark strip surface
  static const Color secondaryBg = Color(0xFFE5E5E0); // Gray-cream secondary
  static const Color secondaryPressed = Color(0xFFC8C8C1);

  // Dividers & Hairlines
  static const Color hairline = Color(0xFFDADAD3);
  static const Color hairlineSoft = Color(0xFFE5E5E0);

  // Text & Ink
  static const Color ink = Color(0xFF000000);
  static const Color inkSoft = Color(0xFF211922);
  static const Color body = Color(0xFF33332E);
  static const Color charcoal = Color(0xFF262622);
  static const Color mute = Color(0xFF62625B);
  static const Color ash = Color(0xFF91918C);
  static const Color stone = Color(0xFFC8C8C1);

  // Semantics
  static const Color focusOuter = Color(0xFF435EE5);
  static const Color successDeep = Color(0xFF103C25);
  static const Color successPale = Color(0xFFC7F0DA);
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

  // Primary Button Style per DESIGN.md (Height 40-44, rounded 16px or custom pill, Pinterest Red)
  static ButtonStyle primaryButtonStyle({
    double height = 44,
    double? radius,
    EdgeInsetsGeometry? padding,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: canvas,
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

  // Secondary Button Style per DESIGN.md (Gray-cream fill, dark text, rounded 16px or custom pill)
  static ButtonStyle secondaryButtonStyle({
    double height = 44,
    double? radius,
    EdgeInsetsGeometry? padding,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: secondaryBg,
      foregroundColor: ink,
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
  static BoxDecoration pillOnImageDecoration() {
    return BoxDecoration(
      color: canvas,
      borderRadius: BorderRadius.circular(radiusFull),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Card Decoration (Warm-cream or white, 16px radius, no drop shadows)
  static BoxDecoration cardDecoration({bool soft = false, bool border = true}) {
    return BoxDecoration(
      color: soft ? surfaceCard : canvas,
      borderRadius: BorderRadius.circular(radiusMd),
      border: border ? Border.all(color: hairlineSoft, width: 1) : null,
    );
  }

  // Large Modal Decoration (White, 32px radius, soft ambient shadow)
  static BoxDecoration modalDecoration() {
    return BoxDecoration(
      color: canvas,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(radiusLg)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 32,
          offset: const Offset(0, -8),
        ),
      ],
    );
  }
}
