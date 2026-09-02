import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/datasources/local/addon_catalog.dart';
import '../../../domain/entities/addon.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Painel do super admin — gestão de add-ons (preço, disponibilidade).
///
/// Permite ao super admin:
/// - Visualizar todos os add-ons do catálogo
/// - Editar preço mensal
/// - Activar/desactivar disponibilidade
/// - Ver quantos tenants têm cada add-on activo
class AdminAddOnsScreen extends ConsumerStatefulWidget {
  const AdminAddOnsScreen({super.key});

  @override
  ConsumerState<AdminAddOnsScreen> createState() => _AdminAddOnsScreenState();
}

class _AdminAddOnsScreenState extends ConsumerState<AdminAddOnsScreen> {
  final List<AddOn> _addOns = AddOnCatalog.addOns();
  final Map<String, bool> _availability = {};
  final Map<String, int> _prices = {};

  @override
  void initState() {
    super.initState();
    for (final addon in _addOns) {
      _availability[addon.id] = addon.isAvailable;
      _prices[addon.id] = addon.priceMonthlyCents;
    }
  }

  void _openEditor(AddOn addon) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddOnEditorSheet(
        addon: addon,
        currentPrice: _prices[addon.id] ?? addon.priceMonthlyCents,
        isAvailable: _availability[addon.id] ?? addon.isAvailable,
        onSave: (priceCents, isAvailable) {
          setState(() {
            _prices[addon.id] = priceCents;
            _availability[addon.id] = isAvailable;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final activeCount =
        _addOns.where((a) => _availability[a.id] ?? a.isAvailable).length;
    final inactiveCount = _addOns.length - activeCount;


    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Stats compacto ──
          SliverToBoxAdapter(
            child: _CompactStats(
              total: _addOns.length,
              active: activeCount,
              inactive: inactiveCount,
            ),
          ),

          // ── Lista de add-ons ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList.separated(
              itemCount: _addOns.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                indent: 40,
                endIndent: 0,
              ),
              itemBuilder: (_, i) => _AddOnTile(
                addon: _addOns[i],
                price: _prices[_addOns[i].id] ?? _addOns[i].priceMonthlyCents,
                isAvailable:
                    _availability[_addOns[i].id] ?? _addOns[i].isAvailable,
                onTap: () => _openEditor(_addOns[i]),
                onToggle: () {
                  setState(() {
                    final id = _addOns[i].id;
                    _availability[id] = !(_availability[id] ?? true);
                  });
                },
              ),
            ),
          ),

          // ── Bottom padding ──
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xxl),
          ),
        ],
      ),
    );
  }
}

// ─── Stats compacto ──────────────────────────────────────────────────────────

class _CompactStats extends StatelessWidget {
  const _CompactStats({
    required this.total,
    required this.active,
    required this.inactive,
  });

  final int total;
  final int active;
  final int inactive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          _Pill(count: total, label: 'Total', color: scheme.onSurface),
          const SizedBox(width: AppSpacing.xs),
          _Pill(
            count: active,
            label: 'Disponíveis',
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.xs),
          _Pill(
            count: inactive,
            label: 'Indisponíveis',
            color: AppColors.statusError,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Tile de add-on ──────────────────────────────────────────────────────────

class _AddOnTile extends StatelessWidget {
  const _AddOnTile({
    required this.addon,
    required this.price,
    required this.isAvailable,
    required this.onTap,
    required this.onToggle,
  });

  final AddOn addon;
  final int price;
  final bool isAvailable;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final iconData = _iconForName(addon.iconName);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // ── Color accent bar ──
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: isAvailable ? scheme.primary : scheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // ── Icon ──
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (isAvailable ? scheme.primary : scheme.outline)
                    .withValues(alpha: 0.12),
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(
                iconData,
                size: 18,
                color: isAvailable ? scheme.primary : scheme.outline,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(text: addon.name),
                        TextSpan(
                          text:
                              '  ${Formatters.currency(price)}/mês',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    addon.category.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // ── Toggle ──
            Switch(
              value: isAvailable,
              onChanged: (_) => onToggle(),
            ),

            Icon(
              Icons.chevron_right,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForName(String name) {
    switch (name) {
      case 'receipt_long':
        return Icons.receipt_long_outlined;
      case 'request_quote':
        return Icons.request_quote_outlined;
      case 'analytics':
        return Icons.analytics_outlined;
      case 'groups':
        return Icons.groups_outlined;
      case 'storefront':
        return Icons.storefront_outlined;
      case 'phone_android':
        return Icons.phone_android_outlined;
      default:
        return Icons.extension_outlined;
    }
  }
}

// ─── Editor sheet ────────────────────────────────────────────────────────────

class _AddOnEditorSheet extends StatefulWidget {
  const _AddOnEditorSheet({
    required this.addon,
    required this.currentPrice,
    required this.isAvailable,
    required this.onSave,
  });

  final AddOn addon;
  final int currentPrice;
  final bool isAvailable;
  final Function(int priceCents, bool isAvailable) onSave;

  @override
  State<_AddOnEditorSheet> createState() => _AddOnEditorSheetState();
}

class _AddOnEditorSheetState extends State<_AddOnEditorSheet> {
  late final _priceController = TextEditingController(
    text: (widget.currentPrice / 100).toStringAsFixed(0),
  );
  late bool _isAvailable = widget.isAvailable;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Editar Add-on',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Add-on info
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: AppRadius.smAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.addon.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.addon.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.addon.category.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.addon.id,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Price field
            AppTextField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              label: 'Preço mensal (MT)',
              prefixIcon: Icons.attach_money,
            ),
            const SizedBox(height: AppSpacing.md),

            // Availability toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Disponível para compra'),
              subtitle: Text(
                _isAvailable
                    ? 'Add-on visível no marketplace dos tenants'
                    : 'Add-on oculto — tenants não podem activar',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              value: _isAvailable,
              onChanged: (value) => setState(() => _isAvailable = value),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Save button
            AppButton.primary(
              expanded: true,
              label: 'Guardar Alterações',
              onPressed: () {
                final priceCents = Money.parse(_priceController.text.trim());
                widget.onSave(priceCents, _isAvailable);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.addon.name} actualizado'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
