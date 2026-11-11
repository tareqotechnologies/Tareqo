import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Paleta de cores OFICIAL do sistema (identidade Outfit):
/// Azul #0067FF, Cinza de superfície #E7E5E5, Branco suave #F9F9F9,
/// Tinta escura #232323.
///
/// Usada pelos modelos de factura personalizada e cotação. As chaves são
/// estáveis (pt) — o nome exibido ao usuário vem de [paletteColorName].
///
/// Nota: as cores de template são escolha DO UTILIZADOR para o documento
/// impresso (identidade própria da empresa dele) — todas derivam da
/// paleta oficial (`AppColors.brandBlue/surfaceGray/softWhite/brandInk`).
const kColorPalettes = <String, Color>{
  'Preto': AppColors.brandInk,
  'Cinza': AppColors.surfaceGray,
  'Azul': AppColors.brandBlue,
  'Branco gelo': AppColors.softWhite,
};

/// Nome localizado da cor da paleta (chave interna → texto visível).
String paletteColorName(String key, AppLocalizations l10n) {
  switch (key) {
    case 'Preto':
      return l10n.paletteSoftBlack;
    case 'Cinza':
      return l10n.paletteWarmGray;
    case 'Azul':
      return l10n.paletteBlue;
    case 'Branco gelo':
      return l10n.paletteBeige;
    default:
      return l10n.paletteSoftBlack;
  }
}
