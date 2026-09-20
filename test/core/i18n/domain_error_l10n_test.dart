import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tareqo/core/i18n/domain_error_l10n.dart';
import 'package:tareqo/domain/repositories/i_employee_account_service.dart';
import 'package:tareqo/domain/usecases/add_customer_use_case.dart';
import 'package:tareqo/domain/usecases/add_debt_use_case.dart';
import 'package:tareqo/domain/usecases/add_employee_use_case.dart';
import 'package:tareqo/domain/usecases/add_financial_transaction_use_case.dart';
import 'package:tareqo/domain/usecases/add_plan_use_case.dart';
import 'package:tareqo/domain/usecases/add_product_use_case.dart';
import 'package:tareqo/domain/usecases/add_store_use_case.dart';
import 'package:tareqo/domain/usecases/close_cash_register_use_case.dart';
import 'package:tareqo/domain/usecases/request_plan_upgrade_use_case.dart';
import 'package:tareqo/domain/usecases/request_tenant_access_use_case.dart';
import 'package:tareqo/l10n/generated/app_localizations.dart';

void main() {
  // Locale pt: os valores localizados coincidem com as mensagens PT das
  // exceções (fallback) — mas o mapeamento é por TIPO/CODE, não por texto.
  final l10n = lookupAppLocalizations(const Locale('pt'));

  group('domainErrorMessage — mapeamento por tipo (variante única)', () {
    test('cliente, dívida, transação, caixa, preço, loja e tenant', () {
      expect(
        domainErrorMessage(
          const InvalidCustomerException('Informe o nome do cliente.'),
          l10n,
        ),
        'Informe o nome do cliente.',
      );
      expect(
        domainErrorMessage(
          const InvalidDebtAmountException('O valor da dívida deve ser maior que zero.'),
          l10n,
        ),
        'O valor da dívida deve ser maior que zero.',
      );
      expect(
        domainErrorMessage(
          const InvalidAmountException('O valor da transação deve ser maior que zero.'),
          l10n,
        ),
        'O valor da transação deve ser maior que zero.',
      );
      expect(
        domainErrorMessage(
          const InvalidCashCountException('A contagem física não pode ser negativa.'),
          l10n,
        ),
        'A contagem física não pode ser negativa.',
      );
      expect(
        domainErrorMessage(
          const InvalidPriceException('O preço de venda (100) não pode ser menor que o preço de compra (200).'),
          l10n,
        ),
        'O preço de venda não pode ser menor que o preço de compra.',
      );
      expect(
        domainErrorMessage(
          const InvalidStoreException('Informe o nome da loja.'),
          l10n,
        ),
        'Informe o nome da loja.',
      );
      expect(
        domainErrorMessage(
          const TenantNotApprovedException('Seu acesso ao ERP ainda não foi aprovado.'),
          l10n,
        ),
        'Seu acesso ao ERP ainda não foi aprovado.',
      );
    });
  });

  group('domainErrorMessage — mapeamento por code (variantes múltiplas)', () {
    test('InvalidEmployeeException: emptyNameOrEmail vs noStore', () {
      expect(
        domainErrorMessage(
          const InvalidEmployeeException('x', code: 'noStore'),
          l10n,
        ),
        'Escolha uma loja do seu tenant.',
      );
      expect(
        domainErrorMessage(
          const InvalidEmployeeException('x', code: 'emptyNameOrEmail'),
          l10n,
        ),
        'Informe nome e e-mail do funcionário.',
      );
    });

    test('InvalidPlanException: quatro variantes', () {
      expect(
        domainErrorMessage(
          const InvalidPlanException('x', code: 'minStores'),
          l10n,
        ),
        'O plano deve permitir ao menos 1 loja.',
      );
      expect(
        domainErrorMessage(
          const InvalidPlanException('x', code: 'minEmployees'),
          l10n,
        ),
        'O plano deve permitir ao menos 1 funcionário.',
      );
      expect(
        domainErrorMessage(
          const InvalidPlanException('x', code: 'negativePrice'),
          l10n,
        ),
        'O preço não pode ser negativo.',
      );
      expect(
        domainErrorMessage(
          const InvalidPlanException('x', code: 'emptyName'),
          l10n,
        ),
        'Informe o nome do plano.',
      );
    });

    test('InvalidTenantRequestException: três variantes', () {
      expect(
        domainErrorMessage(
          const InvalidTenantRequestException('x', code: 'noPlan'),
          l10n,
        ),
        'Escolha um plano.',
      );
      expect(
        domainErrorMessage(
          const InvalidTenantRequestException('x', code: 'alreadyRegistered'),
          l10n,
        ),
        'Você já possui um cadastro de acesso. Aguarde a aprovação.',
      );
      expect(
        domainErrorMessage(
          const InvalidTenantRequestException('x', code: 'emptyBusinessName'),
          l10n,
        ),
        'Informe o nome do seu negócio.',
      );
    });

    test('InvalidPlanRequestException: três variantes', () {
      expect(
        domainErrorMessage(
          const InvalidPlanRequestException('x', code: 'samePlan'),
          l10n,
        ),
        'Escolha um plano diferente do atual.',
      );
      expect(
        domainErrorMessage(
          const InvalidPlanRequestException('x', code: 'pendingRequest'),
          l10n,
        ),
        'Já existe um pedido de upgrade aguardando aprovação.',
      );
      expect(
        domainErrorMessage(
          const InvalidPlanRequestException('x', code: 'notApproved'),
          l10n,
        ),
        'Seu acesso ao ERP ainda não foi aprovado.',
      );
    });

    test('EmployeeAccountCreationException: variantes da RPC', () {
      expect(
        domainErrorMessage(
          const EmployeeAccountCreationException('x', code: 'emailInUse'),
          l10n,
        ),
        'Já existe uma conta com este e-mail. Use outro e-mail ou peça ao funcionário para entrar com a conta dele.',
      );
      expect(
        domainErrorMessage(
          const EmployeeAccountCreationException('x', code: 'ownerOnly'),
          l10n,
        ),
        'Apenas o dono do tenant pode cadastrar funcionários.',
      );
      expect(
        domainErrorMessage(
          const EmployeeAccountCreationException('x', code: 'weakPassword'),
          l10n,
        ),
        'A senha deve ter pelo menos 8 caracteres.',
      );
      expect(
        domainErrorMessage(
          const EmployeeAccountCreationException('x', code: 'noStore'),
          l10n,
        ),
        'Escolha uma loja do seu tenant.',
      );
      expect(
        domainErrorMessage(
          const EmployeeAccountCreationException('x', code: 'generic'),
          l10n,
        ),
        'Não foi possível criar a conta do funcionário. Tente novamente.',
      );
    });
  });

  group('domainErrorMessage — interpolação estruturada', () {
    test('PlanLimitExceededException: lojas e funcionários com plural', () {
      expect(
        domainErrorMessage(
          const PlanLimitExceededException(
            'msg antiga',
            planName: 'Essencial',
            limit: 1,
            forEmployees: true,
          ),
          l10n,
        ),
        'O plano Essencial permite até 1 funcionário. Solicite um upgrade de plano para contratar mais.',
      );
      expect(
        domainErrorMessage(
          const PlanLimitExceededException(
            'msg antiga',
            planName: 'Empresa',
            limit: 10,
          ),
          l10n,
        ),
        'O plano Empresa permite até 10 lojas. Solicite um upgrade de plano para criar mais.',
      );
    });
  });
}
