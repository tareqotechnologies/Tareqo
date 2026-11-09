import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/l10n/generated/app_localizations.dart';
import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/presentation/navigation/app_routes.dart';
import 'package:tareqo/presentation/screens/support/doc_reader_screen.dart';

import '../../helpers/test_app.dart';

/// Testes de navegação por nomes (U-09): tabela de rotas, argumentos
/// tipados, deep links internos `tareqo://go/<rota>` e rota desconhecida.
void main() {
  group('AppRoutes.parseGoDeepLink', () {
    test('mapeia links internos para nomes de rota', () {
      expect(
        AppRoutes.parseGoDeepLink(Uri.parse('tareqo://go/purchases')),
        AppRoutes.purchases,
      );
      expect(
        AppRoutes.parseGoDeepLink(Uri.parse('tareqo://go/addons/quotation')),
        AppRoutes.addonQuotation,
      );
      expect(
        AppRoutes.parseGoDeepLink(Uri.parse('tareqo://go/reports')),
        AppRoutes.reports,
      );
    });

    test('rejeita links de autenticação e rotas desconhecidas', () {
      // Auth (gotrue/PKCE) nunca é rota interna.
      expect(
        AppRoutes.parseGoDeepLink(Uri.parse('tareqo://callback?code=x')),
        isNull,
      );
      expect(
        AppRoutes.parseGoDeepLink(Uri.parse('tareqo://go/unknown')),
        isNull,
      );
      expect(
        AppRoutes.parseGoDeepLink(Uri.parse('https://example.com/go')),
        isNull,
      );
    });
  });

  group('AppRoutes.onGenerateRoute', () {
    testWidgets('resolve rota com argumentos (docReader)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(child: testAppWithRoutes(home: const _Probe())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-doc'));
      await tester.pumpAndSettle();

      expect(find.byType(DocReaderScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rota desconhecida mostra ecrã de erro, sem lançar', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: testAppWithRoutes(home: const _Probe())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-unknown'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Rota não encontrada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('argumentos com tipo errado caem no ecrã de erro', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: testAppWithRoutes(home: const _Probe())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-bad-stores'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Rota não encontrada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// App de teste com a mesma tabela de rotas do `TareqoApp`.
Widget testAppWithRoutes({required Widget home}) {
  registerTestSecureStorage();
  return MaterialApp(
    home: home,
    onGenerateRoute: AppRoutes.onGenerateRoute,
    onUnknownRoute: AppRoutes.unknownRoute,
    theme: AppTheme.dark,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt'),
  );
}

class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () => AppNavigator.pushWith(
              context,
              AppRoutes.docReader,
              {'document': SupportDocument.userGuide},
            ),
            child: const Text('open-doc'),
          ),
          TextButton(
            onPressed: () => AppNavigator.push(context, '/rota-que-nao-existe'),
            child: const Text('open-unknown'),
          ),
          TextButton(
            onPressed: () => AppNavigator.pushWith(context, AppRoutes.stores, {
              'tenant': 'não-é-um-tenant',
            }),
            child: const Text('open-bad-stores'),
          ),
        ],
      ),
    );
  }
}
