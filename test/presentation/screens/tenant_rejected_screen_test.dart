import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/auth_event.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/repositories/i_auth_repository.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/screens/account/tenant_rejected_screen.dart';

/// Fake do [IAuthRepository] para exercitar o botão "Sair da conta".
class _FakeAuthRepository implements IAuthRepository {
  int signOutCalls = 0;

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async => throw UnimplementedError();

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }

  @override
  Future<void> resetPassword({required String email}) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> setNewPassword({required String newPassword}) async {}

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Stream<AuthEvent> get authEvents => const Stream.empty();
}

Tenant _rejectedTenant({String? reason}) => Tenant(
  id: 'tn1',
  ownerUserId: '1',
  businessName: 'Comercial Demo',
  planId: 'pl2',
  status: TenantStatus.rejected,
  rejectionReason: reason,
  createdAt: DateTime(2026, 7, 1),
);

Widget _buildApp(Tenant tenant, IAuthRepository authRepository) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
    child: testApp(home: TenantRejectedScreen(tenant: tenant)),
  );
}

void main() {
  testWidgets('exibe título, nome do negócio e o motivo da rejeição', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        _rejectedTenant(reason: 'Dados de identificação incompletos.'),
        _FakeAuthRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Solicitação rejeitada'), findsOneWidget);
    expect(
      find.text('A solicitação de "Comercial Demo" não foi aprovada.'),
      findsOneWidget,
    );
    expect(find.text('Dados de identificação incompletos.'), findsOneWidget);
    expect(find.text('Terminar sessão'), findsOneWidget);
  });

  testWidgets('não exibe o motivo quando ausente', (tester) async {
    await tester.pumpWidget(
      _buildApp(_rejectedTenant(), _FakeAuthRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Solicitação rejeitada'), findsOneWidget);
    // Sem o card de motivo (apenas o ícone info_outline estaria lá).
    expect(find.byIcon(Icons.info_outline), findsNothing);
  });

  testWidgets('o botão Sair da conta chama o SignOutUseCase', (tester) async {
    final auth = _FakeAuthRepository();

    await tester.pumpWidget(_buildApp(_rejectedTenant(reason: 'Razão'), auth));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminar sessão'));
    await tester.pumpAndSettle();

    expect(auth.signOutCalls, 1);
  });
}
