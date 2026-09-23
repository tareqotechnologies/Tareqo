import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:tareqo/presentation/controllers/invoice_template_providers.dart';

void main() {
  setUp(() {
    // Backend IN-MEMORY para a API async (SharedPreferencesAsync usa
    // SharedPreferencesAsyncPlatform.instance — estático; o mock legado
    // setMockInitialValues não cobre esta API).
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    // Isola testes (instância estática compartilhada).
    SharedPreferencesAsyncPlatform.instance = null;
  });

  group('InvoiceTemplateConfig serialização', () {
    test('round-trip preserva todos os campos', () {
      final config = InvoiceTemplateConfig(
        logoBytes: Uint8List.fromList(const [1, 2, 3, 255]),
        businessName: 'Farmácia Vida',
        businessAddress: 'Av. 24 de Julho, 100',
        businessPhone: '840000000',
        businessTaxId: '400123456',
        primaryColor: const Color(0xFFB58863),
        templateStyle: 'Modern',
      );

      final json = config.toJson();
      final restored = InvoiceTemplateConfig.fromJson(json);

      expect(restored.businessName, 'Farmácia Vida');
      expect(restored.businessAddress, 'Av. 24 de Julho, 100');
      expect(restored.businessPhone, '840000000');
      expect(restored.businessTaxId, '400123456');
      expect(restored.primaryColor, const Color(0xFFB58863));
      expect(restored.templateStyle, 'Modern');
      expect(restored.logoBytes, isNotNull);
      expect(restored.logoBytes, Uint8List.fromList(const [1, 2, 3, 255]));
    });

    test('JSON malformado/deviant cai no default sem quebrar', () {
      final restored = InvoiceTemplateConfig.fromJson(const {
        'name': 42, // tipo errado
        'color': 'não-int',
        'style': 'Inexistente',
      });

      expect(restored.businessName, '');
      expect(restored.primaryColor, const Color(0xFF3D4D55));
      expect(restored.templateStyle, 'Classic');
      expect(restored.logoBytes, isNull);
    });
  });

  group('InvoiceTemplateNotifier (persistência)', () {
    test('save grava no prefs e o build seguinte recarrega', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Estado inicial: default.
      expect(container.read(invoiceTemplateProvider).businessName, '');
      expect(container.read(invoiceTemplateProvider).templateStyle, 'Classic');

      // Salva um template preenchido.
      await container.read(invoiceTemplateProvider.notifier).save(
        InvoiceTemplateConfig(
          businessName: 'Loja Centro',
          primaryColor: const Color(0xFFDC2626),
          templateStyle: 'Compact',
        ),
      );

      expect(
        container.read(invoiceTemplateProvider).businessName,
        'Loja Centro',
      );
      expect(
        container.read(invoiceTemplateProvider).primaryColor,
        const Color(0xFFDC2626),
      );
      expect(container.read(invoiceTemplateProvider).templateStyle, 'Compact');

      // NOVO container (simula reabrir o app): o build recarrega do prefs
      // — o bug era perder tudo e o PDF sair com design padrão.
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      // A carga é async (canal do prefs) — pequeno polling até aplicar.
      for (var i = 0; i < 100; i++) {
        if (container2.read(invoiceTemplateProvider).businessName ==
            'Loja Centro') {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(
        container2.read(invoiceTemplateProvider).businessName,
        'Loja Centro',
      );
      expect(container2.read(invoiceTemplateProvider).templateStyle, 'Compact');
    });

    test('templateStyle inválido salvo é normalizado na leitura', () async {
      // Grava um valor fora do enum conhecido diretamente no backend.
      await SharedPreferencesAsyncPlatform.instance!.setString(
        'invoice_template:custom_invoice',
        '{"name":"Loja","style":"Quebrado"}',
        const SharedPreferencesOptions(),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      for (var i = 0; i < 100; i++) {
        if (container.read(invoiceTemplateProvider).businessName == 'Loja') {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(container.read(invoiceTemplateProvider).templateStyle, 'Classic');
    });

    test('sem backend de prefs, save não lança (estado em memória)', () async {
      // Sem plataforma registada → construtor lança StateError;
      // o notifier deve engolir e manter o estado em memória.
      SharedPreferencesAsyncPlatform.instance = null;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(invoiceTemplateProvider.notifier).save(
        InvoiceTemplateConfig(businessName: 'Sem Prefs'),
      );

      expect(container.read(invoiceTemplateProvider).businessName, 'Sem Prefs');
    });
  });
}
