import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/admin_message.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/admin_message_providers.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_picker_field.dart';
import '../../../core/observability/crash_reporting.dart';

/// Templates profissionais para cada tipo de mensagem admin→tenant.
///
/// Quando o admin seleciona um tipo, o título e o corpo são preenchidos
/// automaticamente com um texto profissional e amigável. O admin pode
/// editar antes de enviar.
class _MessageTemplates {
  /// Cotação de cobrança — valor, período e detalhes do plano.
  static Map<String, String> billingQuote(
    String planName,
    String amount,
    String period,
    String dueDate,
  ) => {
    'title': 'Cotação de Plano — $planName',
    'body':
        'Olá!\n\n'
        'Segue a cotação para renovação do seu plano *$planName* '
        'referente ao período de $period.\n\n'
        '📋 *Detalhes:*\n'
        '• Plano: $planName\n'
        '• Valor: $amount\n'
        '• Período: $period\n'
        '• Data de vencimento: $dueDate\n\n'
        'Por favor, efetue o pagamento até à data de vencimento '
        'para garantir a continuidade do serviço.\n\n'
        'Em caso de dúvidas, entre em contacto com o nosso suporte.\n\n'
        'Cumprimentos,\n'
        'Equipa TAREQO',
  };

  /// Alteração de validade — nova data de expiração.
  static Map<String, String> planExpiryChange(
    String planName,
    String newExpiryDate,
    String reason,
  ) => {
    'title': 'Alteração de Validade — $planName',
    'body':
        'Olá!\n\n'
        'Informamos que a validade do seu plano *$planName* foi '
        'actualizada.\n\n'
        '📋 *Nova validade:*\n'
        '• Plano: $planName\n'
        '• Nova data de expiração: $newExpiryDate\n'
        '• Motivo: $reason\n\n'
        'Caso tenha alguma questão, não hesite em contactar-nos.\n\n'
        'Cumprimentos,\n'
        'Equipa TAREQO',
  };

  /// Aviso de plano expirando em breve.
  static Map<String, String> planExpiringSoon(
    String planName,
    String expiryDate,
    String daysLeft,
  ) => {
    'title': '⚠️ Plano a Expirar — $planName',
    'body':
        'Olá!\n\n'
        'O seu plano *$planName* está prestes a expirar em '
        '*$daysLeft dias*.\n\n'
        '📋 *Detalhes:*\n'
        '• Plano: $planName\n'
        '• Data de expiração: $expiryDate\n\n'
        'Para evitar a interrupção do serviço, recomendamos a '
        'renovação antecipada. Acesse a secção de Facturas no '
        'aplicativo para verificar a cotação.\n\n'
        'Se já efetuou o pagamento, pode ignorar esta mensagem.\n\n'
        'Cumprimentos,\n'
        'Equipa TAREQO',
  };

  /// Mensagem geral — templates pré-definidos por categoria.
  static Map<String, String> general() => {'title': '', 'body': ''};
}

/// Painel do super admin — enviar mensagens/cotações para tenants.
///
/// Sistema de templates: ao selecionar o tipo de mensagem, os campos
/// título e corpo são preenchidos automaticamente com textos profissionais.
/// O admin pode personalizar antes de enviar.
class AdminMessagesScreen extends ConsumerStatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  ConsumerState<AdminMessagesScreen> createState() =>
      _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends ConsumerState<AdminMessagesScreen> {
  Tenant? _selectedTenant;
  AdminMessageType _selectedType = AdminMessageType.general;
  bool _templateApplied = false;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _applyTemplate(AdminMessageType type) {
    if (_selectedTenant == null) return;

    final planName = _planName(_selectedTenant!.planId);
    final now = DateTime.now();
    final period = DateFormat('MMMM yyyy', 'pt').format(now);
    final amount = '5,000.00 MZN';
    final dueDate = DateFormat(
      'dd/MM/yyyy',
    ).format(now.add(const Duration(days: 7)));
    final expiryDate = _selectedTenant!.planExpiresAt != null
        ? DateFormat('dd/MM/yyyy').format(_selectedTenant!.planExpiresAt!)
        : dueDate;
    final daysLeft = _selectedTenant!.planExpiresAt != null
        ? _selectedTenant!.planExpiresAt!.difference(now).inDays.toString()
        : '7';

    final template = switch (type) {
      AdminMessageType.billingQuote => _MessageTemplates.billingQuote(
        planName,
        amount,
        period,
        dueDate,
      ),
      AdminMessageType.planExpiryChange => _MessageTemplates.planExpiryChange(
        planName,
        expiryDate,
        'Ajuste administrativo',
      ),
      AdminMessageType.planExpiringSoon => _MessageTemplates.planExpiringSoon(
        planName,
        expiryDate,
        daysLeft,
      ),
      AdminMessageType.general => _MessageTemplates.general(),
    };

    setState(() {
      _templateApplied = true;
      if (template['title']!.isNotEmpty) {
        _titleController.text = template['title']!;
      }
      if (template['body']!.isNotEmpty) {
        _bodyController.text = template['body']!;
      }
    });
  }

  String _planName(String planId) {
    final plans = ref.read(allPlansProvider).value ?? const [];
    return plans.where((p) => p.id == planId).firstOrNull?.name ?? planId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tenants = ref.watch(allTenantsProvider).value ?? const <Tenant>[];
    final approvedTenants = tenants
        .where((t) => t.status == TenantStatus.approved)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminMessagesTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Selecionar tenant ──
              _SectionLabel(label: l10n.adminMessagesTenantLabel),
              const SizedBox(height: 8),
              AppPickerField<Tenant>(
                value: _selectedTenant,
                isExpanded: true,
                hint: context.l10n.adminMessagesTenantHint,
                items: [
                  for (final tenant in approvedTenants)
                    DropdownMenuItem(
                      value: tenant,
                      child: Text(
                        tenant.businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTenant = value;
                    _templateApplied = false;
                  });
                  // Auto-aplicar template se tipo já selecionado.
                  if (_selectedType != AdminMessageType.general &&
                      value != null) {
                    _applyTemplate(_selectedType);
                  }
                },
                validator: (_) => _selectedTenant == null
                    ? l10n.adminMessagesTenantError
                    : null,
              ),

              // ── Info do tenant seleccionado ──
              if (_selectedTenant != null) ...[
                const SizedBox(height: 8),
                _TenantInfoChip(tenant: _selectedTenant!, planName: _planName),
              ],

              const SizedBox(height: 20),

              // ── Tipo de mensagem (templates) ──
              _SectionLabel(label: l10n.adminMessagesTypeLabel),
              const SizedBox(height: 4),
              Text(
                'Selecionar um tipo preenche automaticamente os campos',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              _TemplateGrid(
                selected: _selectedType,
                l10n: l10n,
                onSelect: (type) {
                  setState(() {
                    _selectedType = type;
                    _templateApplied = false;
                  });
                  if (_selectedTenant != null) {
                    _applyTemplate(type);
                  }
                },
              ),

              const SizedBox(height: 20),

              // ── Título ──
              _SectionLabel(label: l10n.adminMessagesTitleLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: theme.textTheme.bodySmall,
                decoration: InputDecoration(
                  hintText: context.l10n.adminMessagesTitleExample,
                  hintStyle: TextStyle(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.adminMessagesTitleError
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Corpo ──
              _SectionLabel(label: l10n.adminMessagesBodyLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyController,
                maxLines: 8,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
                decoration: InputDecoration(
                  hintText: context.l10n.adminMessagesBodyHint,
                  hintStyle: TextStyle(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.adminMessagesBodyError
                    : null,
              ),

              // ── Indicador de template aplicado ──
              if (_templateApplied) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Template aplicado — edite conforme necessário',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // ── Preview ──
              if (_titleController.text.isNotEmpty &&
                  _bodyController.text.isNotEmpty) ...[
                _MessagePreview(
                  title: _titleController.text,
                  body: _bodyController.text,
                ),
                const SizedBox(height: 20),
              ],

              // ── Botão enviar ──
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, size: 18),
                  label: l10n.adminMessagesSubmit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final tenant = _selectedTenant!;

    try {
      await ref
          .read(sendAdminMessageUseCaseProvider)
          .call(
            tenantId: tenant.id,
            type: _selectedType,
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
          );
      if (!mounted) return;
      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _selectedTenant = null;
        _selectedType = AdminMessageType.general;
        _templateApplied = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminMessagesSendSuccess)),
      );
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao enviar mensagem admin',
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminMessagesSendError)),
      );
    }
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

/// Label de secção minimalista.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}

/// Chip informativo do tenant selecionado.
class _TenantInfoChip extends StatelessWidget {
  const _TenantInfoChip({required this.tenant, required this.planName});

  final Tenant tenant;
  final String Function(String) planName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.business_outlined, size: 14, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${tenant.businessName} · ${planName(tenant.planId)}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: scheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (tenant.planExpiresAt != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.calendar_today_outlined,
              size: 12,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat('dd/MM').format(tenant.planExpiresAt!),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Grid de templates por tipo — cards compactos com ícone e descrição.
class _TemplateGrid extends StatelessWidget {
  const _TemplateGrid({
    required this.selected,
    required this.l10n,
    required this.onSelect,
  });

  final AdminMessageType selected;
  final dynamic l10n;
  final ValueChanged<AdminMessageType> onSelect;

  @override
  Widget build(BuildContext context) {
    final templates = [
      (
        AdminMessageType.billingQuote,
        Icons.request_quote_outlined,
        'Cotação',
        'Valor, período e vencimento',
        AppColors.statusInfo,
      ),
      (
        AdminMessageType.planExpiryChange,
        Icons.calendar_month_outlined,
        'Alterar Validade',
        'Nova data de expiração',
        AppColors.statusPurple,
      ),
      (
        AdminMessageType.planExpiringSoon,
        Icons.schedule_outlined,
        'Plano a Expirar',
        'Aviso antecipado ao tenant',
        AppColors.statusWarning,
      ),
      (
        AdminMessageType.general,
        Icons.mail_outline,
        'Mensagem Livre',
        'Texto personalizado',
        AppColors.statusIndigo,
      ),
    ];

    return Column(
      children: [
        for (final t in templates) ...[
          _TemplateCard(
            type: t.$1,
            icon: t.$2,
            title: t.$3,
            subtitle: t.$4,
            color: t.$5,
            isSelected: selected == t.$1,
            onTap: () => onSelect(t.$1),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Card de template individual — estilo minimalista.
class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final AdminMessageType type;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : scheme.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isSelected ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? color : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

/// Preview da mensagem antes de enviar.
class _MessagePreview extends StatelessWidget {
  const _MessagePreview({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Preview',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
