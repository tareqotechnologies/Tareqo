import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../widgets/app_card.dart';

/// Ecra de gestão de funcionários — ponto, comissões e metas.
///
/// BLOCKED — DEPENDÊNCIA INTERNA (schema): o add-on `ao_employee_mgmt`
/// foi desactivado no catálogo porque ponto/comissões/metas não têm
/// backend nem schema em lado nenhum (nem SQLite nem Supabase). A gestão
/// REAL de funcionários (contas, lojas e cargos) já existe no módulo
/// Lojas. Esta tela só é alcançável por instalações que activaram o
/// add-on ANTES do bloqueio — por isso mostra apenas o estado honesto,
/// nunca dados de demonstração.
class EmployeeManagementScreen extends ConsumerStatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  ConsumerState<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState
    extends ConsumerState<EmployeeManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.employeeMgmtTitle),
      ),
      body: _EmployeeBlockedBanner(message: l10n.employeeMgmtBlockedBanner),
    );
  }
}

/// Banner honesto: ponto/comissões/metas ainda sem backend real — a
/// gestão REAL de funcionários vive no módulo Lojas.
class _EmployeeBlockedBanner extends StatelessWidget {
  const _EmployeeBlockedBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = IconTone.amber;

    return SafeArea(
      top: false,
      child: AppCard(
        color: warning.withValues(alpha: 0.08),
        borderColor: warning.withValues(alpha: 0.30),
        borderRadius: const BorderRadius.all(Radius.circular(0)),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: warning,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}