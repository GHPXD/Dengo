import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tema visual do aplicativo Dengo.
///
/// Implementa o design system "Modern HealthTech" com:
/// - Paleta semântica (verde/amarelo/vermelho para níveis de risco)
/// - Tipografia legível e profissional (Montserrat)
/// - Componentes com bordas arredondadas e sombras suaves
/// - Responsividade e acessibilidade
///
/// Este tema será fundamental na apresentação do TCC,
/// demonstrando cuidado com UX e design profissional.
class AppTheme {
  AppTheme._(); // Construtor privado

  // ══════════════════════════════════════════════════════════════════════════
  // TEMA LIGHT (Principal)
  // ══════════════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ────────────────────────────────────────────────────────────────────────
      // ESQUEMA DE CORES
      // ────────────────────────────────────────────────────────────────────────
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.danger,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: AppColors.background,

      // ────────────────────────────────────────────────────────────────────────
      // TIPOGRAFIA (Google Fonts - Montserrat)
      // ────────────────────────────────────────────────────────────────────────
      textTheme: GoogleFonts.montserratTextTheme().copyWith(
        // Títulos grandes (Hero sections)
        headlineLarge: GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),

        // Títulos médios (Cards principais)
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        // Títulos pequenos (Seções)
        titleLarge: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        titleMedium: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),

        // Corpo de texto
        bodyLarge: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
          height: 1.5, // Line height para legibilidade
        ),

        bodyMedium: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
          height: 1.5,
        ),

        // Labels e botões
        labelLarge: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      // ────────────────────────────────────────────────────────────────────────
      // CARDS (Elevação e bordas suaves)
      // ────────────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ────────────────────────────────────────────────────────────────────────
      // APPBAR
      // ────────────────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // ────────────────────────────────────────────────────────────────────────
      // BOTÕES (Elevated, Outlined, Text)
      // ────────────────────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ────────────────────────────────────────────────────────────────────────
      // INPUT FIELDS
      // ────────────────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: GoogleFonts.montserrat(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.montserrat(color: AppColors.textTertiary),
      ),

      // ────────────────────────────────────────────────────────────────────────
      // DIVIDER
      // ────────────────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 32,
      ),

      // ────────────────────────────────────────────────────────────────────────
      // FLOATING ACTION BUTTON
      // ────────────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TEMA DARK (Futuro, caso deseje implementar)
  // ══════════════════════════════════════════════════════════════════════════

  // static ThemeData get darkTheme {
  //   // TODO: Implementar tema escuro para acessibilidade
  // }
}
