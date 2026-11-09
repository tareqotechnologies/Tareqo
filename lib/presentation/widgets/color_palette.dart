import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Paleta de cores OFICIAL do sistema (4 cores — identidade 2026-11-09):
/// Laranja #FF6A2A, Cinza de superfície #F0F0F0, Branco suave #F9F9F9,
/// Preto #0C0B0A.
///
/// Usada pelos modelos de factura personalizada e cotação. As chaves são
/// estáveis (pt) — o nome exibido ao usuário vem de [paletteColorName].
///
/// Nota: as cores de template são escolha DO UTILIZADOR para o documento
/// impresso (identidade própria da empresa dele) — todas derivam da
/// paleta oficial (`AppColors.brandOrange/surfaceGray/softWhite/brandBlack`).
const kColorPalettes = <String, Color>{
  'Preto': AppColors.brandBlack,
  'Cinza': AppColors.surfaceGray,
  'Terracota': AppColors.brandOrange,
  'Branco gelo': AppColors.softWhite,
};

/// Nome localizado da cor da paleta (chave interna → texto visível).
String paletteColorName(String key, AppLocalizations l10n) {
  switch (key) {
    case 'Preto':
      return l10n.paletteSoftBlack;
    case 'Cinza':
      return l10n.paletteWarmGray;
    case 'Terracota':
      return l10n.paletteTerracotta;
    case 'Branco gelo':
      return l10n.paletteBeige;
    default:
      return l10n.paletteSoftBlack;
  }
}
