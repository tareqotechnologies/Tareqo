import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/app.dart';
import 'package:tareqo/core/utils/formatters.dart';
import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/admin_providers.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';

import '../helpers/store_context.dart';

/// Propagação de PONTA A PONTA: o [TareqoApp] observa o
/// [tenantSettingsProvider] — derivado do tenant (moeda + idioma escolhidos
/// pelo dono) — e aplica no `MaterialApp.locale` e no [Formatters].
///
/// Aqui o tenant nasce PENDING (fluxo logo após o onboarding, sem depender
/// dos providers dos módulos do ERP): mesmo assim, o app inteiro já abre
/// em inglês e formata em Metical (MZN) — a escolha vale da tela de espera
/// em diante.
void main() {
 // [Formatters] é estado global estático — cada teste começa do padrão,
 // mesmo que um teste anterior do arquivo tenha falhado no meio.
 setUp(() {
 Formatters.applySettings(currencyCode: 'BRL', language: 'pt');
 });

 testWidgets('app abre em inglês (locale en) com tenant en + MZN e '
 'formata valores em Metical', (tester) async {
 final tenant = Tenant(
 id: 'tn1',
 ownerUserId: 'u1',
 businessName: 'Comercial Demo',
 planId: 'pl2',
 status: TenantStatus.pending,
 createdAt: DateTime.now(),
 language: 'en',
 currencyCode: 'MZN',
 );

 await tester.pumpWidget(
 ProviderScope(
 overrides: [
 authStateProvider.overrideWith(
 (ref) => Stream.value(AppUser(id: 'u1', email: 'dono@loja.com')),
 ),
 adminRepositoryProvider.overrideWithValue(
 const FakeAdminRepository(),
 ),
 getMyTenantUseCaseProvider.overrideWithValue(
 FakeGetMyTenantUseCase(tenant),
 ),
 ],
 child: const TareqoApp(),
 ),
 );
 await tester.pumpAndSettle();

 // Locale do MaterialApp trocou para en (l10n do app em inglês).
 final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
 expect(app.locale, const Locale('en'));

 // A tela exibida (tenant pending) já está em inglês.
 expect(find.text('Waiting for approval'), findsOneWidget);

 // Formatters aplicou a moeda/idioma do tenant (formato en_US + MZN).
 expect(Formatters.currentLanguage, 'en');
 expect(Formatters.currentCurrencyCode, 'MZN');
 expect(Formatters.currency(123450), 'MZN 1,234.50');
 });

 testWidgets('app sem sessão abre em pt e mantém MZN', (tester) async {
 await tester.pumpWidget(
 ProviderScope(
 overrides: [
 authStateProvider.overrideWith((ref) => Stream.value(null)),
 adminRepositoryProvider.overrideWithValue(
 const FakeAdminRepository(),
 ),
 ],
 child: const TareqoApp(),
 ),
 );
 await tester.pumpAndSettle();

 final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
 // Sem sessão → sem tenant → padrão pt + MZN (metical — mercado-alvo).
 expect(app.locale, const Locale('pt'));
 expect(Formatters.currentLanguage, 'pt');
 expect(Formatters.currentCurrencyCode, 'MZN');
 });
}
