import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/usecases/get_plans_use_case.dart';
import 'package:tareqo/domain/usecases/request_tenant_access_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/screens/account/tenant_onboarding_screen.dart';

class _FakeGetPlansUseCase implements GetPlansUseCase {
 @override
 Future<List<Plan>> call() async => const [
 Plan(
 id: 'pl2',
 name: 'Profissional',
 description: 'Para negócios em crescimento',
 priceMonthlyCents: 19990,
 maxStores: 3,
 maxEmployees: 10,
 ),
 ];
}

/// Fake do [RequestTenantAccessUseCase] que CAPTURA os argumentos do dono
/// (plano, moeda e idioma) — é a prova de que a escolha do onboarding
/// chega à solicitação gravada no banco.
class _CapturingRequestTenantAccess implements RequestTenantAccessUseCase {
 String? ownerUserId;
 String? businessName;
 String? planId;
 String? currencyCode;
 String? language;

 @override
 Future<Tenant> call({
 required String ownerUserId,
 required String businessName,
 required String planId,
 required String currencyCode,
 required String language,
 }) async {
 this.ownerUserId = ownerUserId;
 this.businessName = businessName;
 this.planId = planId;
 this.currencyCode = currencyCode;
 this.language = language;
 return Tenant(
 id: 'tn1',
 ownerUserId: ownerUserId,
 businessName: businessName,
 planId: planId,
 status: TenantStatus.pending,
 createdAt: DateTime.now(),
 currencyCode: currencyCode,
 language: language,
 );
 }
}

const _user = AppUser(id: 'u1', email: 'dono@loja.com');

Widget _build(_CapturingRequestTenantAccess request, {Locale locale = const Locale('pt')}) {
 return ProviderScope(
 overrides: [
 getPlansUseCaseProvider.overrideWithValue(_FakeGetPlansUseCase()),
 requestTenantAccessUseCaseProvider.overrideWithValue(request),
 ],
 child: testApp(home: TenantOnboardingScreen(user: _user), locale: locale),
 );
}

/// Lê o estado `selected` do ChoiceChip pelo rótulo (idioma/moeda).
bool _chipSelected(WidgetTester tester, String label) {
 final chip = tester.widget<ChoiceChip>(
 find.ancestor(of: find.text(label), matching: find.byType(ChoiceChip)),
 );
 return chip.selected;
}

/// Rola o [SingleChildScrollView] até o elemento ficar visível e toca — o
/// formulário do onboarding é mais alto que o viewport de teste (800×600).
Future<void> _tap(WidgetTester tester, String text) async {
 final finder = find.text(text);
 await tester.ensureVisible(finder);
 await tester.pumpAndSettle();
 await tester.tap(finder);
 await tester.pumpAndSettle();
}

void main() {
 testWidgets('onboarding renderiza plano, moeda e idioma com padrões pt/MZN',
 (tester) async {
 await tester.pumpWidget(_build(_CapturingRequestTenantAccess()));
 await tester.pumpAndSettle();

 expect(find.text('Bem-vindo!'), findsOneWidget);
 expect(find.text('Nome do negócio'), findsOneWidget);
 // Idioma: padrão Português selecionado (os 3 idiomas aparecem).
 expect(find.text('Português'), findsOneWidget);
 expect(find.text('English'), findsOneWidget);
 expect(find.text('Français'), findsOneWidget);
 expect(_chipSelected(tester, 'Português'), isTrue);
 expect(_chipSelected(tester, 'English'), isFalse);
 expect(_chipSelected(tester, 'Français'), isFalse);
 // Moeda: as 4 opções, padrão Metical (MZN) selecionado (mercado-alvo).
 expect(find.text('Real (BRL)'), findsOneWidget);
 expect(find.text('Dólar (USD)'), findsOneWidget);
 expect(find.text('Euro (EUR)'), findsOneWidget);
 expect(find.text('Metical (MZN)'), findsOneWidget);
 expect(_chipSelected(tester, 'Metical (MZN)'), isTrue);
 expect(_chipSelected(tester, 'Real (BRL)'), isFalse);
 // Plano carregado + botão de submit.
 expect(find.text('Profissional'), findsOneWidget);
 expect(find.text('Solicitar acesso'), findsOneWidget);
 });

 testWidgets('validação: negócio vazio e plano não escolhido bloqueiam o envio',
 (tester) async {
 final request = _CapturingRequestTenantAccess();
 await tester.pumpWidget(_build(request));
 await tester.pumpAndSettle();

 // Sem nome do negócio (e sem plano) → erro do campo.
 await _tap(tester, 'Solicitar acesso');
 expect(find.text('Informe o nome do seu negócio.'), findsOneWidget);
 expect(request.planId, isNull, reason: 'nada deve ser enviado');

 // Com nome, mas sem plano → erro de plano.
 await tester.enterText(find.byType(TextFormField), 'Mercado Central');
 await tester.pump();
 await _tap(tester, 'Solicitar acesso');
 expect(find.text('Escolha um plano para continuar.'), findsOneWidget);
 expect(request.planId, isNull, reason: 'nada deve ser enviado');
 });

 testWidgets('dono escolhe inglês + metical (MZN) + plano e a solicitação '
 'captura as escolhas', (tester) async {
 final request = _CapturingRequestTenantAccess();
 await tester.pumpWidget(_build(request));
 await tester.pumpAndSettle();

 await tester.enterText(find.byType(TextFormField), 'Mercado Central');
 // Idioma → English; moeda → Metical (MZN); plano → Profissional.
 await _tap(tester, 'English');
 await _tap(tester, 'Metical (MZN)');
 await _tap(tester, 'Profissional');

 expect(_chipSelected(tester, 'English'), isTrue);
 expect(_chipSelected(tester, 'Metical (MZN)'), isTrue);

 await _tap(tester, 'Solicitar acesso');

 // A escolha do dono chega à solicitação (persistida no tenant).
 expect(request.ownerUserId, 'u1');
 expect(request.businessName, 'Mercado Central');
 expect(request.planId, 'pl2');
 expect(request.language, 'en');
 expect(request.currencyCode, 'MZN');

 // Feedback de sucesso com o nome do negócio.
 expect(find.textContaining('Solicitação de'), findsOneWidget);
 expect(find.textContaining('Mercado Central'), findsWidgets);
 });

 testWidgets('a tela inteira renderiza em inglês com o locale en',
 (tester) async {
 await tester.pumpWidget(
 _build(_CapturingRequestTenantAccess(), locale: const Locale('en')),
 );
 await tester.pumpAndSettle();

 expect(find.text('Welcome!'), findsOneWidget);
 expect(find.text('Business name'), findsOneWidget);
 expect(find.text('Portuguese'), findsOneWidget);
 expect(find.text('English'), findsOneWidget);
 expect(find.text('Français'), findsOneWidget);
 expect(find.text('Mozambican Metical (MZN)'), findsOneWidget);
 expect(find.text('Choose a plan'), findsOneWidget);
 expect(find.text('Request access'), findsOneWidget);
 });

 testWidgets('dono escolhe francês e a solicitação captura fr',
 (tester) async {
 final request = _CapturingRequestTenantAccess();
 await tester.pumpWidget(_build(request));
 await tester.pumpAndSettle();

 await tester.enterText(find.byType(TextFormField), 'Marché Central');
 await _tap(tester, 'Français');
 await _tap(tester, 'Profissional');

 expect(_chipSelected(tester, 'Français'), isTrue);

 await _tap(tester, 'Solicitar acesso');

 expect(request.ownerUserId, 'u1');
 expect(request.businessName, 'Marché Central');
 expect(request.language, 'fr');
 expect(request.currencyCode, 'MZN');
 });

 testWidgets('a tela inteira renderiza em francês com o locale fr',
 (tester) async {
 await tester.pumpWidget(
 _build(_CapturingRequestTenantAccess(), locale: const Locale('fr')),
 );
 await tester.pumpAndSettle();

 expect(find.text('Bienvenue !'), findsOneWidget);
 expect(find.text('Nom de l\'entreprise'), findsOneWidget);
 expect(find.text('Português'), findsOneWidget);
 expect(find.text('English'), findsOneWidget);
 expect(find.text('Français'), findsOneWidget);
 expect(find.text('Metical (MZN)'), findsOneWidget);
 expect(find.text('Choisissez le forfait'), findsOneWidget);
 expect(find.text('Demander l\'accès'), findsOneWidget);
 });
}
