import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Paleta de cores OFICIAL do sistema (identidade 2026 — "Shades of gray"):
/// Preto 100 #0A0E15, Preto 60 #667085, Branco 90 #F0F1F5, Branco 100
/// #FFFFFF. Sem laranja.
///
/// Usada pelos modelos de factura personalizada e cotação. As chaves são
/// estáveis (pt) — o nome exibido ao usuário vem de [paletteColorName].
///
/// Nota: as cores de template são escolha DO UTILIZADOR para o documento
/// impresso (identidade própria da empresa dele) — todas derivam da
/// escala neutra (`AppColors`).
const kColorPalettes = <String, Color>{
  'Preto': AppColors.black100,
  'Cinza': AppColors.lightSurfaceSecondary,
  // Chave legada ('Azul'/'Laranja' em versões anteriores): mantida para
  // não invalidar templates guardados; o valor é o cinza Preto 60.
  'Azul': AppColors.black60,
  'Branco gelo': AppColors.white100,
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
