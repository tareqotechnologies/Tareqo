import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Paleta de cores OFICIAL do sistema (4 cores — nova identidade):
/// Preto #212121, Cinza #757575, Terracota #B7472A, Branco gelo #E0E0E0.
///
/// Usada pelos modelos de factura personalizada e cotação. As chaves são
/// estáveis (pt) — o nome exibido ao usuário vem de [paletteColorName].
///
/// Nota: as cores de template são escolha DO UTILIZADOR para o documento
/// impresso (identidade própria da empresa dele) — todas derivam da
/// paleta oficial (`AppColors.black/gray/terracotta/ice`).
const kColorPalettes = <String, Color>{
  'Preto': AppColors.black,
  'Cinza': AppColors.gray,
  'Terracota': AppColors.terracotta,
  'Branco gelo': AppColors.ice,
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
