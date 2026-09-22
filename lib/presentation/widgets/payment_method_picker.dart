import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/i18n/payment_method_l10n.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/entities/sale.dart';
import 'payment_filter.dart' show PaymentMethodIcon;

/// Seletor de forma de pagamento — design system 2026 (igual ao app de
/// referência): métodos PRIMÁRIOS (Dinheiro, Cartão de débito, Cartão de
/// crédito) como abas segmentadas e métodos SECUNDÁRIOS (M-Pesa, E-Mola,
/// Transferência) como lista com indicador de seleção (radio).
///
/// No rodapé das sheets o seletor fica RECOLHIDO por padrão: uma única
/// linha de 48dp com o método atual — tocar expande o seletor completo e
/// a seleção recolhe de volta. Sem isso, o seletor completo (~237px)
/// espreme o catálogo em telas baixas (a lista de produtos ficava com
/// menos de 30px na viewport de teste) e o toque no stepper caía no
/// rodapé. Compartilhado pelo carrinho de Vendas e de Compras — mesma
/// linguagem visual nos dois fluxos.
class PaymentMethodPicker extends StatefulWidget {
  const PaymentMethodPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.initiallyExpanded = false,
  });

  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;

  /// Expandido na abertura (usado em superfícies onde o seletor é o
  /// conteúdo principal, não o rodapé).
  final bool initiallyExpanded;

  @override
  State<PaymentMethodPicker> createState() => _PaymentMethodPickerState();
}

class _PaymentMethodPickerState extends State<PaymentMethodPicker> {
  /// Métodos primários: abas segmentadas (uma linha).
  static const List<PaymentMethod> _primary = [
    PaymentMethod.cash,
    PaymentMethod.debitCard,
    PaymentMethod.creditCard,
  ];

  /// Métodos secundários: lista com radio.
  static const List<PaymentMethod> _secondary = [
    PaymentMethod.mPesa,
    PaymentMethod.eMola,
    PaymentMethod.transfer,
  ];

  late bool _expanded = widget.initiallyExpanded;

  void _select(PaymentMethod method) {
    widget.onChanged(method);
    // A seleção fecha o seletor: o rodapé volta ao resumo de 48dp e o
    // catálogo recupera o espaço imediatamente.
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!_expanded) {
      return _CollapsedSummary(
        label: widget.value.labelFor(l10n),
        icon: widget.value.icon,
        onTap: () => setState(() => _expanded = true),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // -------------------------------------------------------------
        // Primários — abas segmentadas (3 em linha)
        // -------------------------------------------------------------
        Row(
          children: [
            for (final method in _primary) ...[
              if (method != _primary.first) const SizedBox(width: 8),
              Expanded(
                child: _PrimaryTab(
                  label: method.labelFor(l10n),
                  icon: method.icon,
                  selected: widget.value == method,
                  onTap: () => _select(method),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // -------------------------------------------------------------
        // Secundários — lista com radio
        // -------------------------------------------------------------
        for (final method in _secondary) ...[
          _SecondaryTile(
            label: method.labelFor(l10n),
            icon: method.icon,
            selected: widget.value == method,
            onTap: () => _select(method),
          ),
          if (method != _secondary.last) const SizedBox(height: 4),
        ],
      ],
    );
  }
}

/// Estado recolhido: uma linha de 48dp com o método selecionado — alvo de
/// toque acessível sem ocupar o rodapé inteiro.
class _CollapsedSummary extends StatelessWidget {
  const _CollapsedSummary({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.expand_more,
                size: 22,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aba segmentada de método primário — contorno verde quando selecionada.
class _PrimaryTab extends StatelessWidget {
  const _PrimaryTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 3),
              // Quebra em até 2 linhas centralizadas em vez de encolher
              // (FittedBox deixava 'Cartão de débito' ilegível em telas
              // estreitas) — a aba cresce verticalmente, o texto é completo.
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  height: 1.25,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Linha de método secundário — ícone + rótulo + radio de seleção.
class _SecondaryTile extends StatelessWidget {
  const _SecondaryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Container(
          // Padding vertical 14: linha com ≥ 48dp de altura — alvo de toque
          // acessível (WCAG/androidTapTargetGuideline). Era 6 (≈37px).
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: selected ? primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? primary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  // Quebra em até 2 linhas — o nome do método nunca é cortado.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Radio de seleção: círculo cheio verde quando ativo.
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 22,
                color: selected ? primary : theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
