import 'package:flutter/material.dart';

/// Centralized color palette for the TourneyZone esports application.
///
/// Designed with a dark navy & obsidian aesthetic, vibrant electric blue primary,
/// restrained fiery orange secondary accents, crisp typography, and high contrast.
class AppColors {
  AppColors._();

  // Dark Theme Core Palette (Primary esport look)
  static const Color darkBackground = Color(0xFF090D16); // Deep Obsidian / Dark Navy
  static const Color darkSurface = Color(0xFF111827);    // Navy Card Surface
  static const Color darkSurfaceElevated = Color(0xFF1E293B); // Higher elevation card
  static const Color darkSurfaceBorder = Color(0xFF334155); // Card and input border
  static const Color darkSurfaceBorderSubtle = Color(0xFF1E293B);

  // Primary Accent: Electric Blue
  static const Color electricBlue = Color(0xFF00E5FF);       // High-voltage cyan/electric blue
  static const Color electricBlueDark = Color(0xFF00B0FF);   // Slightly deeper tone for hover/press
  static const Color electricBlueDim = Color(0x2200E5FF);    // 13% opacity for glow / chips
  static const Color electricBlueBorder = Color(0x6600E5FF); // 40% opacity border

  // Secondary Highlight: Subtle Fiery Orange
  static const Color fieryOrange = Color(0xFFFF6D00);        // Vivid esports orange accent
  static const Color fieryOrangeDim = Color(0x22FF6D00);     // Subtle orange badge background
  static const Color fieryOrangeBorder = Color(0x66FF6D00);  // Subtle orange border

  // Aliases for UI convenience
  static const Color neonOrange = fieryOrange;
  static const Color neonOrangeDim = fieryOrangeDim;
  static const Color neonOrangeBorder = fieryOrangeBorder;

  // Semantic Colors
  static const Color success = Color(0xFF10B981);            // Emerald 500
  static const Color successDim = Color(0x1F10B981);
  static const Color warning = Color(0xFFF59E0B);            // Amber 500
  static const Color warningDim = Color(0x1FF59E0B);
  static const Color error = Color(0xFFEF4444);              // Crimson Red 500
  static const Color errorDim = Color(0x1FEF4444);
  static const Color info = Color(0xFF38BDF8);               // Sky 400
  static const Color infoDim = Color(0x1F38BDF8);

  // Status Indicators
  static const Color statusPending = Color(0xFFF59E0B);      // Amber
  static const Color statusApproved = Color(0xFF10B981);     // Emerald
  static const Color statusRejected = Color(0xFFEF4444);     // Crimson

  // Text Colors (Dark Mode)
  static const Color textPrimary = Color(0xFFF8FAFC);        // Pure Crisp Off-White
  static const Color textSecondary = Color(0xFF94A3B8);      // Slate 400
  static const Color textMuted = Color(0xFF64748B);          // Slate 500
  static const Color textDisabled = Color(0xFF475569);       // Slate 600

  // Light Theme Palette (Clean professional esports mode)
  static const Color lightBackground = Color(0xFFF1F5F9);    // Clean slate light
  static const Color lightSurface = Color(0xFFFFFFFF);       // Crisp white
  static const Color lightSurfaceElevated = Color(0xFFF8FAFC);
  static const Color lightSurfaceBorder = Color(0xFFCBD5E1);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient electricGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF0077FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeAccentGradient = LinearGradient(
    colors: [Color(0xFFFF8A00), Color(0xFFFF5252)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF131D2E), Color(0xFF0D1420)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroBackgroundGradient = LinearGradient(
    colors: [Color(0xFF090D16), Color(0xFF0F172A), Color(0xFF06090F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

