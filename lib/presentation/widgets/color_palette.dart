import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Paleta de cores profissional — tonalidades sóbrias da paleta RE2
/// (`lib/core/theme/app_colors.dart`), consistentes com o design system
/// do app (sem cores de tendência/AI, sem verde — regra RE2).
///
/// Usada pelos modelos de factura personalizada e cotação. As chaves são
/// estáveis (pt) — o nome exibido ao usuário vem de [paletteColorName].
///
/// Nota: as cores de template são escolha DO UTILIZADOR para o documento
/// impresso (identidade própria da empresa dele), então incluem os matizes
/// da paleta base + os dois derivados já auditados do sistema (`brandMuted`
/// e o petrol médio de Relatórios). Hexa sem token direto = valor documentado
/// no guard (`hex_guard_test.dart`).
const kColorPalettes = <String, Color>{
  'Petroleo': Color(0xFF10282A),
  'Slate': Color(0xFF3D4D55),
  'Terracota': Color(0xFFB58863),
  'Bege': Color(0xFFD3C3B9),
  'Cinza quente': Color(0xFFA79E9C),
  'Tinta petroleo': Color(0xFF2E6E75),
  'Tinta slate': Color(0xFF2C3E45),
  'Preto suave': Color(0xFF161616),
};

/// Nome localizado da cor da paleta (chave interna → texto visível).
String paletteColorName(String key, AppLocalizations l10n) {
  switch (key) {
    case 'Petroleo':
      return l10n.palettePetrol;
    case 'Slate':
      return l10n.paletteSlate;
    case 'Terracota':
      return l10n.paletteTerracotta;
    case 'Bege':
      return l10n.paletteBeige;
    case 'Cinza quente':
      return l10n.paletteWarmGray;
    case 'Tinta petroleo':
      return l10n.palettePetrolInk;
    case 'Tinta slate':
      return l10n.paletteSlateInk;
    default:
      return l10n.paletteSoftBlack;
  }
}
