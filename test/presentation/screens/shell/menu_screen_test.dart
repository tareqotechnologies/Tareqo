import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/store_context.dart';

import 'package:tareqo/domain/entities/store.dart';
import 'package:tareqo/domain/repositories/i_auth_repository.dart';
import 'package:tareqo/domain/usecases/sign_out_use_case.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/controllers/notification_providers.dart';
import 'package:tareqo/presentation/screens/shell/menu_screen.dart';

/// Spy do caso de uso de logout: registra a chamada sem tocar em auth
/// real (nenhuma credencial, nenhuma rede).
class _SpySignOutUseCase extends SignOutUseCase {
  _SpySignOutUseCase() : super(_NoopAuthRepository());

  int calls = 0;

  @override
  Future<void> call() async {
    calls++;
  }
}

class _NoopAuthRepository implements IAuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('não usado no teste');
}

Future<void> _pump(
  WidgetTester tester,
  _SpySignOutUseCase signOut, {
  List<Store> stores = const [
    Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro'),
  ],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...storeContextOverrides(stores: stores),
        // Badge de não lidas fixo em 3 (o provider real exige o datasource).
        unreadNotificationsCountProvider.overrideWith((ref) async => 3),
        signOutUseCaseProvider.overrideWithValue(signOut),
      ],
      child: testApp(home: const MenuScreen()),
    ),
  );
  // Pumps finitos: o PulseBadge pulsa indefinidamente quando count > 0 —
  // pumpAndSettle nunca terminaria (animação infinita intencional).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

const List<Store> _threeStores = [
  Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro'),
  Store(id: 'st2', tenantId: 'tn1', name: 'Loja Bairro'),
  Store(id: 'st3', tenantId: 'tn1', name: 'Loja Praia'),
];

void main() {
  testWidgets('exibe subtítulo e os módulos do dono (grelha completa)', (
    tester,
  ) async {
    // given — dono de tenant aprovado: acesso total.
    final signOut = _SpySignOutUseCase();
    await _pump(tester, signOut);

    // then — subtítulo e os 9 módulos da grelha.
    expect(find.text('Escolha uma área para continuar'), findsOneWidget);
    expect(find.text('Produtos'), findsOneWidget);
    expect(find.text('Clientes'), findsOneWidget);
    expect(find.text('Crédito'), findsOneWidget);
    expect(find.text('Compras'), findsOneWidget);
    expect(find.text('Relatórios'), findsOneWidget);
    expect(find.text('Lojas'), findsOneWidget);
    expect(find.text('Notificações'), findsOneWidget);
    expect(find.text('Add-ons'), findsOneWidget);
    expect(find.text('Segurança'), findsOneWidget);
  });

  testWidgets('badge de notificações mostra o contador de não lidas', (
    tester,
  ) async {
    // given — 3 notificações não lidas (override do FutureProvider).
    final signOut = _SpySignOutUseCase();
    await _pump(tester, signOut);

    // then — PulseBadge renderiza o número exato (count <= maxCount).
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('terminar sessão pede confirmação e cancelar NÃO desloga', (
    tester,
  ) async {
    // given
    final signOut = _SpySignOutUseCase();
    await _pump(tester, signOut);

    // when — toca na linha de logout.
    await tester.tap(find.text('Terminar sessão'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // then — diálogo de confirmação aparece; o use case ainda não rodou.
    expect(find.text('Terminar sessão?'), findsOneWidget);
    expect(
      find.text('Vai sair da sua conta neste dispositivo.'),
      findsOneWidget,
    );
    expect(signOut.calls, 0);

    // when — cancelar.
    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // then — diálogo fechado, sessão mantida.
    expect(find.text('Terminar sessão?'), findsNothing);
    expect(signOut.calls, 0);
  });

  testWidgets('confirmar o diálogo encerra a sessão (chama o use case)', (
    tester,
  ) async {
    // given
    final signOut = _SpySignOutUseCase();
    await _pump(tester, signOut);

    // when — confirma o logout.
    await tester.tap(find.text('Terminar sessão'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // O botão de confirmação tem o MESMO rótulo da linha — pega o último
    // (o do diálogo, que está por cima).
    await tester.tap(find.text('Terminar sessão').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // then — use case executado exatamente uma vez.
    expect(signOut.calls, 1);
  });

  testWidgets('cartão Lojas navega para a tela de lojas do tenant', (
    tester,
  ) async {
    // given — dono aprovado com as 3 lojas reais do tenant.
    final signOut = _SpySignOutUseCase();
    await _pump(tester, signOut, stores: _threeStores);

    // when — abre as Lojas.
    await tester.tap(find.text('Lojas'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // then — as 3 lojas do tenant renderizam (dados do contexto injetado).
    expect(find.text('Loja Centro'), findsOneWidget);
    expect(find.text('Loja Bairro'), findsOneWidget);
    expect(find.text('Loja Praia'), findsOneWidget);
  });

  testWidgets('cartão Notificações navega para a tela de notificações', (
    tester,
  ) async {
    // given — nenhum use case de notificação overrideado: os providers
    // entram em erro controlado → estado vazio.
    final signOut = _SpySignOutUseCase();
    await _pump(tester, signOut);

    // when — abre Notificações.
    await tester.tap(find.text('Notificações'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // then — estado vazio localizado da tela de notificações.
    expect(find.text('Sem notificações'), findsOneWidget);
  });
}
