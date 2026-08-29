import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../domain/entities/admin_message.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/admin_message_providers.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/app_button.dart';
import '../../../core/observability/crash_reporting.dart';

/// Painel do super admin — enviar mensagens/cotações para tenants.
///
/// O super admin seleciona um tenant, escolhe o tipo de mensagem,
/// preenche título e corpo, e envia. A mensagem aparece no painel
/// de notificações do tenant.
class AdminMessagesScreen extends ConsumerStatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  ConsumerState<AdminMessagesScreen> createState() =>
      _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends ConsumerState<AdminMessagesScreen> {
  Tenant? _selectedTenant;
  AdminMessageType _selectedType = AdminMessageType.general;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tenants =
        ref.watch(allTenantsProvider).value ?? const <Tenant>[];
    final approvedTenants =
        tenants.where((t) => t.status == TenantStatus.approved).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.adminMessagesTitle,
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selecionar tenant
              Text(
                l10n.adminMessagesTenantLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Tenant>(
                initialValue: _selectedTenant,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: [
                  for (final tenant in approvedTenants)
                    DropdownMenuItem(
                      value: tenant,
                      child: Text(tenant.businessName),
                    ),
                ],
                onChanged: (value) => setState(() => _selectedTenant = value),
                validator: (_) =>
                    _selectedTenant == null ? l10n.adminMessagesTenantError : null,
              ),
              const SizedBox(height: 20),

              // Tipo de mensagem
              Text(
                l10n.adminMessagesTypeLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in AdminMessageType.values)
                    ChoiceChip(
                      label: Text(_typeLabel(type, l10n)),
                      selected: _selectedType == type,
                      onSelected: (_) =>
                          setState(() => _selectedType = type),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Título
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.adminMessagesTitleLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? l10n.adminMessagesTitleError
                        : null,
              ),
              const SizedBox(height: 16),

              // Corpo
              TextFormField(
                controller: _bodyController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l10n.adminMessagesBodyLabel,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? l10n.adminMessagesBodyError
                        : null,
              ),
              const SizedBox(height: 24),

              // Botão enviar
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

  String _typeLabel(AdminMessageType type, dynamic l10n) {
    return switch (type) {
      AdminMessageType.billingQuote => l10n.adminMessagesTypeBillingQuote,
      AdminMessageType.planExpiryChange => l10n.adminMessagesTypePlanExpiryChange,
      AdminMessageType.planExpiringSoon => l10n.adminMessagesTypePlanExpiringSoon,
      AdminMessageType.general => l10n.adminMessagesTypeGeneral,
    };
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final tenant = _selectedTenant!;

    try {
      await ref.read(sendAdminMessageUseCaseProvider).call(
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
