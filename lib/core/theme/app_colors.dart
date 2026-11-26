import 'package:flutter/material.dart';

/// Paleta negro + rojo estilo manga:
/// fondo negro, tinta blanco hueso para texto y bordes, sombras duras rojas
/// y bloques en distintos tonos de rojo y grafito.
///
/// Los nombres se conservan para no tocar las pantallas:
/// cada "color de bloque" ahora es un tono rojo o gris oscuro.
class AppColors {
  // Base
  static const paper = Color(0xFF0B0B0B); // fondo
  static const card = Color(0xFF181818); // superficies
  static const ink = Color(0xFFF3EEE6); // texto, íconos y bordes
  static const inkSoft = Color(0xFF9C958C); // texto secundario
  static const shadow = Color(0xFFE10600); // sombra dura

  // Bloques
  static const lime = Color(0xFFE10600); // rojo principal
  static const coral = Color(0xFFFF3B2F); // rojo encendido
  static const cobalt = Color(0xFF7A0A10); // rojo vino
  static const sun = Color(0xFF2E2E2E); // grafito
  static const lilac = Color(0xFF4A0B10); // granate
  static const mint = Color(0xFFB3121B); // carmesí
  static const danger = Color(0xFFFF2D2D);
}
