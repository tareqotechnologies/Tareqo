import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/presentation/widgets/barcode_scan_sheet.dart';

/// O BarcodeScanSheet usa a CÂMERA real (MobileScannerController) — em
/// testes de widget o plugin não existe e o `errorBuilder` entra em ação.
/// O contrato observável: a moldura e o texto guiam o usuário mesmo sem
/// câmera; cancelar devolve null.
///
/// NOTA: pumps FIXOS em vez de pumpAndSettle — o controlador do scanner
/// mantém timers/streams pendentes (event channel de orientação) que
/// nunca "assentam" no ambiente de teste.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Responde às chamadas do method channel do mobile_scanner: sem mock,
  // o MissingPluginException mata a rota antes do frame ser exibido.
  // A resposta devolve uma câmera "parada" — suficiente para o widget
  // montar e o usuário ver a interface de escaneamento.
  const scannerChannel = MethodChannel(
    'dev.steenbakker.mobile_scanner/scanner/method',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(scannerChannel, (call) async {
          switch (call.method) {
            case 'start':
              return {
                'textureId': 0,
                'size': {'width': 1280.0, 'height': 720.0},
                'torchable': false,
              };
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(scannerChannel, null);
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showBarcodeScanner(context),
                child: const Text('escanear'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('escanear'));
    // Frames fixos: entrada da rota (300ms) + resolução do start async.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('o sheet de escaneamento renderiza a moldura e o texto guia', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.byType(BarcodeScanSheet), findsOneWidget);
    // Texto guia do usuário (sempre visível, com ou sem câmera).
    expect(find.textContaining('código de barras'), findsOneWidget);
    // Botão de fechar identificável (acessibilidade).
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('botão fechar devolve null ao chamador (cancelamento)', (
    tester,
  ) async {
    String? popped;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  popped = await showBarcodeScanner(context);
                },
                child: const Text('escanear'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('escanear'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(const Duration(milliseconds: 400));

    // Cancelamento devolve null (contrato do showBarcodeScanner).
    expect(popped, isNull);
  });
}
