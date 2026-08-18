import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/core/config/app_settings.dart';
import 'package:dumbhanengue/domain/entities/app_user.dart';
import 'package:dumbhanengue/domain/entities/tenant.dart';
import 'package:dumbhanengue/presentation/controllers/account_providers.dart';
import 'package:dumbhanengue/presentation/controllers/auth_providers.dart';

import '../../helpers/store_context.dart';

/// Propagação das preferências do dono (moeda + idioma) no lado da LEITURA:
/// [tenantSettingsProvider] é o provider que o `DumbhanengueApp` observa
/// para trocar o locale do MaterialApp e a formatação de moeda. Se o tenant
/// foi salvo com `language = en` e `currencyCode = MZN`, o provider deve
/// expor exatamente isso (e o `Locale` derivado).
void main() {
 Tenant tenantWith({String language = 'pt', String currencyCode = 'BRL'}) =>
 Tenant(
 id: 'tn1',
 ownerUserId: 'u1',
 businessName: 'Comercial Demo',
 planId: 'pl2',
 status: TenantStatus.approved,
 approvedAt: DateTime.now(),
 createdAt: DateTime.now(),
 language: language,
 currencyCode: currencyCode,
 );

 ProviderContainer buildContainer(Tenant tenant) {
 return ProviderContainer(
 overrides: [
 authStateProvider.overrideWith(
 (ref) => Stream.value(AppUser(id: 'u1', email: 'dono@loja.com')),
 ),
 getMyTenantUseCaseProvider.overrideWithValue(
 FakeGetMyTenantUseCase(tenant),
 ),
 ],
 );
 }

 // Atenção: testWidgets (e não test): o StreamProvider da sessão só entrega
 // eventos quando o binding bombeia microtasks (mesma razão do
 // store_isolation_provider_test). O `listen` mantém vivos os providers
 // autoDispose durante a resolução da cadeia.
 Future<AppSettings?> resolveSettings(WidgetTester tester, Tenant tenant) async {
 final container = buildContainer(tenant);
 await tester.pumpWidget(
 const ProviderScope(
 child: MaterialApp(home: Scaffold(body: SizedBox())),
 ),
 );

 final authSub = container.listen(authStateProvider, (_, _) {});
 await tester.pumpAndSettle();
 expect(container.read(authStateProvider).value?.id, 'u1');

 final tenantSub = container.listen(myTenantProvider('u1'), (_, _) {});
 await tester.runAsync(() => container.read(myTenantProvider('u1').future));

 final settings = container.read(tenantSettingsProvider);
 // Fecha as inscrições ANTES de descartar o container (ordem dos
 // tearDowns é a de registro).
 addTearDown(() {
 authSub.close();
 tenantSub.close();
 container.dispose();
 });
 return settings;
 }

 testWidgets('tenant en + MZN propaga AppSettings(en, MZN) e Locale(en)',
 (tester) async {
 final settings = await resolveSettings(
 tester,
 tenantWith(language: 'en', currencyCode: 'MZN'),
 );

 expect(settings, isNotNull);
 expect(settings!.language, 'en');
 expect(settings.currencyCode, 'MZN');
 expect(settings.locale, const Locale('en'));
 });

 testWidgets('tenant padrão (pt + BRL) propaga AppSettings(pt, BRL)',
 (tester) async {
 final settings = await resolveSettings(tester, tenantWith());

 expect(settings, isNotNull);
 expect(settings!.language, 'pt');
 expect(settings.currencyCode, 'BRL');
 expect(settings.locale, const Locale('pt'));
 });

 testWidgets('sem sessão o provider expõe null (app volta ao padrão)',
 (tester) async {
 final container = ProviderContainer(
 overrides: [
 authStateProvider.overrideWith((ref) => Stream.value(null)),
 ],
 );

 await tester.pumpWidget(
 const ProviderScope(
 child: MaterialApp(home: Scaffold(body: SizedBox())),
 ),
 );
 final authSub = container.listen(authStateProvider, (_, _) {});
 await tester.pumpAndSettle();
 addTearDown(() {
 authSub.close();
 container.dispose();
 });

 expect(container.read(tenantSettingsProvider), isNull);
 });
}
