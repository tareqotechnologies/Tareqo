import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/presentation/widgets/confirm_dialog.dart';

import '../../helpers/test_app.dart';

/// Testes do [showConfirmDialog] — o dialog de confirmação unificado:
/// cancelamento como `TextButton` (peso baixo) e acção principal como
/// `AppButton` (`.primary` ou `.danger` conforme `destructive`).
void main() {
  Future<bool?>? result;

  /// Abre o dialog através de um botão (precisa de um BuildContext vivo).
  Future<void> openDialog(
    WidgetTester tester, {
    required String title,
    required String message,
    required String confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    result = null;
    await tester.pumpWidget(
      testApp(
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => result = showConfirmDialog(
                context,
                title: title,
                message: message,
                confirmLabel: confirmLabel,
                cancelLabel: cancelLabel,
                destructive: destructive,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Color? confirmButtonColor(WidgetTester tester, String label) {
    final button = tester.widget<FilledButton>(
      find.ancestor(of: find.text(label), matching: find.byType(FilledButton)),
    );
    // AppButton.primary não define style (default do tema = primary);
    // AppButton.danger define o erro explicitamente no style.
    return button.style?.backgroundColor?.resolve(<WidgetState>{});
  }

  group('showConfirmDialog', () {
    testWidgets('renderiza título, mensagem e acções (Cancelar + confirmar)', (
      tester,
    ) async {
      await openDialog(
        tester,
        title: 'Quitar dívida?',
        message: 'Confirma a baixa de 100,00 MT?',
        confirmLabel: 'Quitar',
      );

      expect(find.text('Quitar dívida?'), findsOneWidget);
      expect(find.text('Confirma a baixa de 100,00 MT?'), findsOneWidget);
      // Cancelamento padrão = chave l10n commonCancel (pt: "Cancelar").
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Quitar'), findsOneWidget);
      // A acção principal é um FilledButton (AppButton), não um TextButton.
      expect(
        find.ancestor(
          of: find.text('Quitar'),
          matching: find.byType(TextButton),
        ),
        findsNothing,
      );
    });

    testWidgets('sem mensagem opcional omite o conteúdo', (tester) async {
      await openDialog(
        tester,
        title: 'Sair?',
        message: 'ignorada', // o helper exige; o teste abaixo reabre sem ela
        confirmLabel: 'Sair',
      );
      // Reabre sem message (null) diretamente.
      result = null;
      await tester.pumpWidget(
        testApp(
          home: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => result = showConfirmDialog(
                  context,
                  title: 'Sair?',
                  confirmLabel: 'Sair',
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Sair?'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);
    });

    testWidgets('não-destrutivo usa a variante primary (não error)', (
      tester,
    ) async {
      await openDialog(
        tester,
        title: 'Confirmar',
        message: 'Detalhe',
        confirmLabel: 'Guardar',
      );
      final scheme = Theme.of(tester.element(find.text('Guardar'))).colorScheme;

      final bg = confirmButtonColor(tester, 'Guardar');
      expect(bg, isNot(scheme.error));
      // Sem style explícito o FilledButton cai no default do tema (primary).
      expect(bg, isNull);
    });

    testWidgets(
      'destrutivo usa a variante danger (error) e confirma com true',
      (tester) async {
        await openDialog(
          tester,
          title: 'Apagar cliente?',
          message: 'Essa acção não pode ser desfeita.',
          confirmLabel: 'Apagar',
          destructive: true,
        );
        final scheme = Theme.of(
          tester.element(find.text('Apagar')),
        ).colorScheme;

        expect(confirmButtonColor(tester, 'Apagar'), scheme.error);

        await tester.tap(find.text('Apagar'));
        await tester.pumpAndSettle();
        expect(await result, isTrue);
      },
    );

    testWidgets('confirmar (não-destrutivo) retorna true e fecha o dialog', (
      tester,
    ) async {
      await openDialog(
        tester,
        title: 'Quitar dívida?',
        message: 'Detalhe',
        confirmLabel: 'Quitar',
      );

      await tester.tap(find.text('Quitar'));
      await tester.pumpAndSettle();

      expect(await result, isTrue);
      expect(find.text('Quitar dívida?'), findsNothing);
    });

    testWidgets('cancelar retorna false', (tester) async {
      await openDialog(
        tester,
        title: 'Cancelar?',
        message: 'Detalhe',
        confirmLabel: 'Ok',
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(await result, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('dismiss pela barreira (tap fora) retorna null', (
      tester,
    ) async {
      await openDialog(
        tester,
        title: 'Fora?',
        message: 'Detalhe',
        confirmLabel: 'Ok',
      );

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(await result, isNull);
    });

    testWidgets('cancelLabel custom substitui o padrão', (tester) async {
      await openDialog(
        tester,
        title: 'Título',
        message: 'Detalhe',
        confirmLabel: 'Ok',
        cancelLabel: 'Depois',
      );

      expect(find.text('Depois'), findsOneWidget);
      expect(find.text('Cancelar'), findsNothing);

      await tester.tap(find.text('Depois'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });
  });
}
