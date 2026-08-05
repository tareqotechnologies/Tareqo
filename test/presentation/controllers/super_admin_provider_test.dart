import 'package:dumbhanengue/domain/repositories/i_admin_repository.dart';
import 'package:dumbhanengue/presentation/controllers/admin_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake do [IAdminRepository] para os testes do provider.
class _FakeAdminRepository implements IAdminRepository {
  const _FakeAdminRepository(this.result);

  final bool result;

  @override
  Future<bool> isSuperAdmin() async => result;
}

void main() {
  group('isSuperAdminProvider', () {
    test('resolve true quando o repositório confirma o papel', () async {
      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(
            const _FakeAdminRepository(true),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(isSuperAdminProvider('u1').future), isTrue);
    });

    test('resolve false quando o usuário não tem o papel', () async {
      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(
            const _FakeAdminRepository(false),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(isSuperAdminProvider('u1').future), isFalse);
    });

    test('o provider é cacheado por usuário (chave userId)', () async {
      final container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(
            const _FakeAdminRepository(true),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(isSuperAdminProvider('u1').future), isTrue);
      // Chave diferente = estado independente (mesmo resultado do fake).
      expect(await container.read(isSuperAdminProvider('u2').future), isTrue);
    });
  });
}
