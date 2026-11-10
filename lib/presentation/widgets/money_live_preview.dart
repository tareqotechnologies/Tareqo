import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/money.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';

/// Preview AO VIVO do valor que será REGISTADO a partir do texto digitado
/// num campo de moeda.
///
/// O [Money.parse] interpreta `"1390"` (sem separador decimal) como
/// **1.390,00** — comportamento correto para quem digita valores grandes,
/// mas também a origem do erro clássico de registrar **100×** o pretendido
/// (o usuário digita "1390" querendo 13,90). Este widget mostra o resultado
/// formatado ENQUANTO o usuário digita, eliminando a ambiguidade antes do
/// save — sem mudar a semântica de [Money.parse] (auditoria A2).
///
/// Some quando o campo está vazio, inválido ou com valor zero.
class MoneyLivePreview extends StatefulWidget {
  const MoneyLivePreview({super.key, required this.controller});

  /// Controller do campo de moeda a observar.
  final TextEditingController controller;

  @override
  State<MoneyLivePreview> createState() => _MoneyLivePreviewState();
}

class _MoneyLivePreviewState extends State<MoneyLivePreview> {
  late String _text = widget.controller.text;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() => _text = widget.controller.text);

  @override
  Widget build(BuildContext context) {
    final cents = Money.parse(_text);
    if (cents <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '= ${Formatters.currency(cents)}',
          style: AppTypography.bodySmall.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
