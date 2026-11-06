import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'premium_decor.dart';

/// Folha de feed — um ÚNICO painel com as linhas separadas por divisórias
/// hairline, a mesma linguagem da lista agrupada de Vendas e dos grupos do
/// Financeiro: o contêiner é a superfície; cada linha entra transparente e
/// com o próprio padding.
///
/// Superfície do cartão (branca no claro) e raio 16 — a regra do sistema:
/// painéis de lista = 16, heroes = 20.
class FeedCard extends StatelessWidget {
  const FeedCard({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);

    // Sombra neutra em camadas por baixo do painel — o mesmo acabamento
    // do AppCard, para listas e cards lerem-se como uma família.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: PremiumDecor.softShadow(theme.colorScheme),
      ),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: PremiumDecor.hairline(theme.colorScheme)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 60,
                  endIndent: AppSpacing.md,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}
