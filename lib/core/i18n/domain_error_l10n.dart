import '../../domain/repositories/i_employee_account_service.dart';
import '../../domain/usecases/add_customer_use_case.dart';
import '../../domain/usecases/add_debt_use_case.dart';
import '../../domain/usecases/add_employee_use_case.dart';
import '../../domain/usecases/add_financial_transaction_use_case.dart';
import '../../domain/usecases/add_plan_use_case.dart';
import '../../domain/usecases/add_product_use_case.dart';
import '../../domain/usecases/add_store_use_case.dart';
import '../../domain/usecases/close_cash_register_use_case.dart';
import '../../domain/usecases/request_plan_upgrade_use_case.dart';
import '../../domain/usecases/request_tenant_access_use_case.dart';
import '../../l10n/generated/app_localizations.dart';

/// Mapeia exceções de domínio para mensagens LOCALIZADAS na exibição.
///
/// As mensagens persistidas nas exceções (`message`) são PT e servem de
/// fallback/legado (mesmo padrão das notificações: dado armazenado, exibição
/// localizada). Exceções com variantes carregam um `code` estável; a
/// [PlanLimitExceededException] carrega campos estruturados para a
/// interpolação (plano + limite + tipo).
///
/// Usar nos `catch` tipados das telas: `_formError = domainErrorMessage(
/// error, l10n)` em vez de `error.message` direto.
String domainErrorMessage(Object error, AppLocalizations l10n) =>
    switch (error) {
      // ── Variantes únicas: mapeamento direto por tipo ──
      InvalidCustomerException() => l10n.validationCustomerNameRequired,
      InvalidDebtAmountException() => l10n.validationDebtAmountPositive,
      InvalidAmountException() => l10n.validationAmountPositive,
      InvalidCashCountException() => l10n.validationCashCountNonNegative,
      InvalidPriceException() => l10n.validationSalePriceBelowPurchase,
      InvalidStoreException() => l10n.validationStoreNameRequired,
      TenantNotApprovedException() => l10n.validationTenantNotApproved,

      // ── Variantes múltiplas: mapeamento por `code` ──
      InvalidEmployeeException() => switch (error.code) {
        'noStore' => l10n.validationEmployeeStoreRequired,
        _ => l10n.validationEmployeeNameEmailRequired,
      },
      InvalidPlanException() => switch (error.code) {
        'minStores' => l10n.validationPlanMinStores,
        'minEmployees' => l10n.validationPlanMinEmployees,
        'negativePrice' => l10n.validationPlanPriceNonNegative,
        _ => l10n.validationPlanNameRequired,
      },
      InvalidTenantRequestException() => switch (error.code) {
        'noPlan' => l10n.validationAccessPlanRequired,
        'alreadyRegistered' => l10n.validationAccessAlreadyRequested,
        _ => l10n.validationBusinessNameRequired,
      },
      InvalidPlanRequestException() => switch (error.code) {
        'samePlan' => l10n.validationUpgradePlanDifferent,
        'pendingRequest' => l10n.validationUpgradePendingExists,
        _ => l10n.validationTenantNotApproved,
      },
      EmployeeAccountCreationException() => switch (error.code) {
        'emailInUse' => l10n.validationAccountEmailInUse,
        'ownerOnly' => l10n.validationAccountOwnerOnly,
        'weakPassword' => l10n.validationAccountWeakPassword,
        'noStore' => l10n.validationEmployeeStoreRequired,
        _ => l10n.validationAccountGeneric,
      },

      // ── Interpolação com dados estruturados ──
      PlanLimitExceededException() =>
        error.forEmployees
            ? l10n.planLimitEmployees(error.planName, error.limit)
            : l10n.planLimitStores(error.planName, error.limit),

      // Fallback defensivo (os catch são tipados; não deveria acontecer).
      _ => () {
        try {
          return (error as dynamic).message as String? ?? error.toString();
        } on Object {
          return error.toString();
        }
      }(),
    };
