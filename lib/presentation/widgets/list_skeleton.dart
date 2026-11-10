import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'skeleton.dart';

/// Skeleton de LISTA — blocos no formato dos cards reais (resumo opcional
/// + N cards) com pulso suave ([Skeleton] compartilhado).
///
/// Usado nos estados de carregamento de Produtos, Clientes, Lojas e demais
/// listagens em vez de um spinner solto: a UI "antecipa" a forma do
/// conteúdo, reduzindo a sensação de espera e padronizando o loading em
/// toda a app.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.items = 6, this.showHeader = false});

  /// Número de blocos-card desenhados.
  final int items;

  /// Desenha um bloco de resumo (tipo cabeçalho do dia) antes dos cards.
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );
    return Skeleton(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          horizontal,
          AppSpacing.sm,
          horizontal,
          AppSpacing.fabBottomClearance,
        ),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          if (showHeader) ...[
            const SkeletonBlock(height: 96, radius: AppRadius.lg),
            const SizedBox(height: AppSpacing.md),
          ],
          for (var i = 0; i < items; i++) ...[
            const SkeletonBlock(height: 72, radius: AppRadius.lg),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
