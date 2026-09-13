import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:tareqo/data/services/product_image_store_local.dart';
import 'package:tareqo/data/services/product_image_store_noop.dart';

/// Fake do [PathProviderPlatform] — diretório temporário REAL: a store
/// local grava as fotos em `<docs>/product_images/` (mesmo padrão dos
/// testes de share/exporters).
class _FakePathProvider extends PathProviderPlatform {
  late Directory docsDir;

  @override
  Future<String?> getApplicationDocumentsPath() async => docsDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fakePP = _FakePathProvider();
  final originalPP = PathProviderPlatform.instance;

  setUp(() async {
    fakePP.docsDir = await Directory.systemTemp.createTemp('tareqo_imgs');
    PathProviderPlatform.instance = fakePP;
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPP;
    await fakePP.docsDir.delete(recursive: true);
  });

  group('ProductImageStoreLocal', () {
    test(
      'deve gravar a foto em product_images/<productId>.jpg e devolver o caminho absoluto',
      () async {
        // given
        const store = ProductImageStoreLocal();
        final bytes = Uint8List.fromList([1, 2, 3, 255, 0, 42]);

        // when
        final path = await store.saveImage(
          productId: 'p1',
          storeId: 'st1',
          bytes: bytes,
        );

        // then — caminho absoluto persistível em products.image_path.
        expect(path, endsWith('product_images${Platform.pathSeparator}p1.jpg'));
        expect(File(path).existsSync(), isTrue);
        expect(File(path).readAsBytesSync(), bytes);
      },
    );

    test(
      'deve sanitizar o nome do arquivo (sem traversal de caminho)',
      () async {
        // given — id hostil não pode escapar do diretório de imagens.
        const store = ProductImageStoreLocal();

        // when
        final path = await store.saveImage(
          productId: r'../../p\x:1',
          storeId: 'st1',
          bytes: Uint8List.fromList([9]),
        );

        // then — só [A-Za-z0-9_-] sobrevive; nada sai do diretório.
        final fileName = path.split(Platform.pathSeparator).last;
        expect(fileName, matches(RegExp(r'^[A-Za-z0-9_-]+\.jpg$')));
        expect(fileName, isNot(contains('/')));
        expect(fileName, isNot(contains(r'\')));
        expect(File(path).existsSync(), isTrue);
      },
    );

    test(
      'deve substituir a foto existente (mesma foto por produto, sem órfão)',
      () async {
        // given — trocar a foto NÃO pode criar segundo arquivo.
        const store = ProductImageStoreLocal();
        final first = await store.saveImage(
          productId: 'p2',
          storeId: 'st1',
          bytes: Uint8List.fromList([1, 1, 1]),
        );

        // when
        final second = await store.saveImage(
          productId: 'p2',
          storeId: 'st1',
          bytes: Uint8List.fromList([2, 2, 2]),
        );

        // then — mesmo caminho, bytes novos, um arquivo só.
        expect(second, first);
        expect(File(second).readAsBytesSync(), [2, 2, 2]);
        expect(
          Directory(
            '${fakePP.docsDir.path}${Platform.pathSeparator}product_images',
          ).listSync().whereType<File>(),
          hasLength(1),
        );
      },
    );

    test('deve excluir a foto existente', () async {
      // given
      const store = ProductImageStoreLocal();
      final path = await store.saveImage(
        productId: 'p3',
        storeId: 'st1',
        bytes: Uint8List.fromList([7]),
      );

      // when
      await store.deleteImage(path);

      // then
      expect(File(path).existsSync(), isFalse);
    });

    test('deve ignorar exclusão de caminho inexistente (sem lançar)', () async {
      // given — produto excluído no servidor já não tem arquivo local.
      const store = ProductImageStoreLocal();
      final ghost =
          '${fakePP.docsDir.path}${Platform.pathSeparator}fantasma.jpg';

      // when / then
      await store.deleteImage(ghost);
      expect(File(ghost).existsSync(), isFalse);
    });

    test(
      'deve tratar caminho vazio como no-op (produto nunca teve foto)',
      () async {
        // given — imagePath == '' é o contrato do modo no-op/local sem foto.
        const store = ProductImageStoreLocal();

        // when / then — não lança.
        await store.deleteImage('');
      },
    );
  });

  group('ProductImageStoreNoop', () {
    test('deve devolver referência vazia (UI mostra o ícone padrão)', () async {
      // given — modo memória (web/testes): não há disco nem Storage.
      const store = ProductImageStoreNoop();

      // when
      final path = await store.saveImage(
        productId: 'p1',
        storeId: 'st1',
        bytes: Uint8List.fromList([1]),
      );

      // then — imagePath == '' é o contrato consumido pela UI.
      expect(path, isEmpty);
    });

    test('deleteImage deve ser no-op sem lançar', () async {
      // given
      const store = ProductImageStoreNoop();

      // when / then
      await store.deleteImage('qualquer/coisa.jpg');
      await store.deleteImage('');
    });
  });
}
