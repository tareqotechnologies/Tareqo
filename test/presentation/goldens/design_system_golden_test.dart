import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_fonts.dart';
import '../../helpers/test_app.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/core/theme/app_tokens.dart';
import 'package:tareqo/presentation/widgets/app_button.dart';
import 'package:tareqo/presentation/widgets/app_card.dart';
import 'package:tareqo/presentation/widgets/app_sheet.dart';
import 'package:tareqo/presentation/widgets/app_text_field.dart';
import 'package:tareqo/presentation/widgets/empty_state.dart';
import 'package:tareqo/presentation/widgets/error_view.dart';
import 'package:tareqo/presentation/widgets/kpi_card.dart';
import 'package:tareqo/presentation/widgets/section_header.dart';
import 'package:tareqo/presentation/widgets/status_chip.dart';

/// Baseline visual do design system — referencia para as fases de evolução
/// UI/UX. Qualquer mudança de tema/tokens/componentes que altere pixels
/// destas superfícies fica visível no diff do golden.
///
/// Regenerar após mudança visual INTENCIONAL:
/// ```
/// flutter test --update-goldens test/presentation/goldens
/// ```
///
/// Escopo deliberado (determinismo):
/// * Skeletons (pulse infinito) ficam FORA — a fase da animação no momento
///   da captura não é reproduzível.
/// * Indicadores de progresso usam `value` determinado (não indeterminado).
///
/// Fontes reais carregadas no setUpAll (`loadGoldenFonts`): sem Outfit e
/// MaterialIcons o framework renderiza a fonte de teste (Ahem) — texto em
/// blocos e ícones em quadrados — e o golden não representa o app.
void main() {
  setUpAll(loadGoldenFonts);

  Future<void> pumpGallery(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      testApp(
        theme: theme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(
                    title: 'Resumo do dia',
                    actionLabel: 'Ver tudo',
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(
                        child: KpiCard(
                          label: 'Vendas de hoje',
                          amountCents: 1245000,
                          icon: Icons.payments_outlined,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: KpiCard(
                          label: 'Produtos',
                          value: '128',
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Filtros'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(
                        label: 'Pago',
                        color: theme.colorScheme.primary,
                        icon: Icons.check_circle_outline,
                      ),
                      StatusChip(
                        label: 'Pendente',
                        color: theme.warning,
                        icon: Icons.schedule,
                      ),
                      StatusChip(
                        label: 'Cancelada',
                        color: theme.colorScheme.error,
                        icon: Icons.cancel_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Formulário'),
                  const SizedBox(height: 12),
                  const AppTextField(
                    label: 'Nome do cliente',
                    hintText: 'Ex.: Ana Costa',
                  ),
                  const SizedBox(height: 12),
                  const AppTextField(
                    label: 'E-mail',
                    errorText: 'Informe um e-mail válido.',
                  ),
                  const SizedBox(height: 12),
                  const AppCard(
                    child: SheetSection(
                      icon: Icons.receipt_long_outlined,
                      title: 'Pagamento',
                      children: [Text('M-Pesa · e-Mola · Dinheiro · Crédito')],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Cabeçalho de sheet'),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                    child: SheetHeader(
                      title: 'Novo produto',
                      subtitle: 'Loja Centro · Catálogo',
                      onSave: () {},
                      actionLabel: 'Guardar',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                    child: SheetHeader(title: 'Detalhes da venda'),
                  ),
                  const SizedBox(height: 24),
                  AppButton.primary(
                    label: 'Registar venda',
                    icon: const Icon(Icons.point_of_sale, size: 18),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  AppButton.secondary(label: 'Cancelar', onPressed: () {}),
                  const SizedBox(height: 12),
                  const AppButton.primary(label: 'Guardar', onPressed: null),
                  const SizedBox(height: 24),
                  const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Nenhum produto',
                    subtitle: 'Adicione o primeiro produto da loja.',
                  ),
                  const SizedBox(height: 24),
                  ErrorView(
                    message: 'Não foi possível carregar os dados.',
                    details: 'Sem conexão com o servidor.',
                    onRetry: () {},
                  ),
                  LinearProgressIndicator(
                    value: 0.4,
                    minHeight: 4,
                    borderRadius: AppRadius.microAll,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('design system — dark', (tester) async {
    await pumpGallery(tester, AppTheme.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/design_system_dark.png'),
    );
  });

  testWidgets('design system — light', (tester) async {
    await pumpGallery(tester, AppTheme.light);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/design_system_light.png'),
    );
  });
}
