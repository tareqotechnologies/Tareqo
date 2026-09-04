import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Paleta de cores profissional — tonalidades sóbrias e consistentes
/// com o design system do app (sem cores de tendência/AI).
///
/// Usada pelos modelos de factura personalizada e cotação. As chaves são
/// estáveis (pt) — o nome exibido ao usuário vem de [_paletteColorName].
const kColorPalettes = <String, Color>{
  'Azul': Color(0xFF2563EB),
  'Verde': Color(0xFF16A34A),
  'Vermelho': Color(0xFFDC2626),
  'Âmbar': Color(0xFFD97706),
  'Slate': Color(0xFF475569),
  'Violeta': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Indigo': Color(0xFF4338CA),
};

/// Nome localizado da cor da paleta (chave interna → texto visível).
String paletteColorName(String key, AppLocalizations l10n) {
  switch (key) {
    case 'Azul':
      return l10n.paletteBlue;
    case 'Verde':
      return l10n.paletteGreen;
    case 'Vermelho':
      return l10n.paletteRed;
    case 'Âmbar':
      return l10n.paletteAmber;
    case 'Slate':
      return l10n.paletteSlate;
    case 'Violeta':
      return l10n.paletteViolet;
    case 'Teal':
      return l10n.paletteTeal;
    default:
      return l10n.paletteIndigo;
  }
}
