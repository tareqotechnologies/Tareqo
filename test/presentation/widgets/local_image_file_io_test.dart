import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/presentation/widgets/local_image_file_io.dart';

void main() {
  // `Image.file` decodifica em tempo real — em testWidgets (FakeAsync) isso
  // nunca completa, então a cobertura aqui é de UNIDADE: construir o widget
  // e verificar a configuração entregue ao [Image]. O pipeline de decode em
  // si é do framework (fora do escopo).
  TestWidgetsFlutterBinding.ensureInitialized();

  test('retorna Image.file com BoxFit.cover', () {
    final widget = localImageFile(
      '/dados/foto.png',
      const Icon(Icons.broken_image),
    );

    expect(widget, isA<Image>());
    final image = widget as Image;
    expect(image.fit, BoxFit.cover);
    expect(image.image, isA<FileImage>());
    expect((image.image as FileImage).file.path, '/dados/foto.png');
  });

  test('cacheWidth vira ResizeImage (decode reduzido p/ thumbnails)', () {
    final widget = localImageFile(
      '/dados/thumb.png',
      const SizedBox.shrink(),
      cacheWidth: 96,
    );

    final image = widget as Image;
    // O provider é embrulhado em ResizeImage com a largura pedida.
    expect(image.image, isA<ResizeImage>());
    expect((image.image as ResizeImage).width, 96);
  });

  testWidgets('fallback chega ao errorBuilder da Image', (tester) async {
    const fallback = Icon(Icons.broken_image);
    final widget = localImageFile('/nao/existe.png', fallback);

    final image = widget as Image;
    // Contexto real capturado de uma árvore mínima (sem imagem — o decode
    // real em FakeAsync nunca completa, por isso nada de Image no pump).
    BuildContext? ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // O builder é o portal do fallback — invocamos diretamente para provar
    // que é ele quem é entregue (o dispara-em-erro é do framework).
    final built = image.errorBuilder!(ctx!, Object(), StackTrace.empty);
    expect(built, same(fallback));
  });
}
