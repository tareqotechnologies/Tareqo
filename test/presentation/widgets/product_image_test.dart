import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/presentation/widgets/product_image.dart';

void main() {
  // Decodificar imagem em FakeAsync nunca completa, então a cobertura aqui é
  // de UNIDADE (mesma abordagem do local_image_file_io_test): construir o
  // widget e verificar a configuração entregue ao [Image] / fallback.
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Contexto com tema, capturado de uma árvore mínima — [ProductImage.build]
  /// precisa de Theme.of(context).
  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext ctx;
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
    return ctx;
  }

  /// Desembrulha a estrutura `ClipRRect > SizedBox > Image`.
  Image imageOf(Widget widget) {
    final clip = widget as ClipRRect;
    final box = clip.child! as SizedBox;
    return box.child! as Image;
  }

  testWidgets('sem imagePath mostra o fallback do ícone', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProductImage(imagePath: '')),
    );

    // Fallback = container quadrado arredondado com ícone de stock.
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(ProductImage),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(12));
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('URL http vira Image.network com cacheWidth = 2× o tamanho', (
    tester,
  ) async {
    final ctx = await pumpContext(tester);

    const widget = ProductImage(imagePath: 'https://cdn.exemplo.com/a.jpg');
    final image = imageOf(widget.build(ctx));

    // Image.network embrulha o provider em ResizeImage (cacheWidth).
    expect(image.image, isA<ResizeImage>());
    final resize = image.image as ResizeImage;
    expect(resize.width, 88); // 2 × 44 — thumbnail nas listas
    final network = resize.imageProvider as NetworkImage;
    expect(network.url, 'https://cdn.exemplo.com/a.jpg');
    expect(image.fit, BoxFit.cover);
  });

  testWidgets('caminho local vira Image.file com ResizeImage do cacheWidth', (
    tester,
  ) async {
    final ctx = await pumpContext(tester);

    const widget = ProductImage(imagePath: '/dados/foto.jpg', size: 60);
    final image = imageOf(widget.build(ctx));

    expect(image.image, isA<ResizeImage>());
    expect((image.image as ResizeImage).width, 120); // 2 × 60
    final fileImage = (image.image as ResizeImage).imageProvider as FileImage;
    expect(fileImage.file.path, '/dados/foto.jpg');
  });

  testWidgets('errorBuilder da rede devolve o fallback (UI nunca vazia)', (
    tester,
  ) async {
    final ctx = await pumpContext(tester);

    const widget = ProductImage(
      imagePath: 'https://cdn.exemplo.com/quebrada.jpg',
    );
    final image = imageOf(widget.build(ctx));

    final built = image.errorBuilder!(ctx, Object(), StackTrace.empty);
    expect(built, isA<Container>());
    final fallback = built as Container;
    final icon = fallback.child! as Icon;
    expect(icon.icon, Icons.inventory_2_outlined);
  });
}
