import 'package:flutter/material.dart';

/// Duração da barra — e do countdown: 4s, acima do padrão de ~3s de
/// leitura; o tempo extra É o custo da segunda chance do undo.
const Duration _undoDuration = Duration(seconds: 4);

/// SnackBar de sucesso com UNDO — o padrão "aço dissipável" do plano
/// UI/UX (Fase 1.3): ações destrutivas REVERSÍVEIS confirmam com esta
/// barra (4s, duração acima do padrão 3s de leitura), deixando o
/// desfazer a um toque. Para ações irreversíveis, continuar usando o
/// `showConfirmDialog` antes de executar — o undo nunca substitui a
/// confirmação explícita, apenas dá uma segunda chance honesta quando a
/// reversão é possível e barata.
///
/// **Animação de progresso (1.3)**: uma linha fina sob a mensagem esvazia
/// ao longo dos 4s — o tempo restante para o "Desfazer" é literalmente
/// visível (o usuário NÃO é surpreendido pela barra a sumir). A cor vem
/// do `actionTextColor` do `snackBarTheme` global (inversão por brilho
/// auditada em `theme_contrast_test.dart`).
///
/// ⚠️ Em testes: com a barra visível o countdown mantém frames agendados —
/// `pumpAndSettle` esgota os 4s e a dispensa. Use pumps cronometrados
/// (`pump()` + `pump(400.milliseconds)`) para inspecioná-la "de pé".
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required String undoLabel,
  required VoidCallback onUndo,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  // Remover a barra anterior: dois undos consecutivos (ex.: apagar dois
  // clientes em sequência) empilham barras — a nova sempre substitui a
  // antiga, e o undo pendente não confirmado simplesmente não roda.
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        duration: _undoDuration,
        behavior: SnackBarBehavior.floating,
        content: _CountdownContent(message: message, duration: _undoDuration),
        action: SnackBarAction(label: undoLabel, onPressed: onUndo),
      ),
    );
}

/// Conteúdo do [showUndoSnackBar]: mensagem + countdown determinado que
/// esvazia ao longo da duração da barra (começa cheio, termina vazio no
/// instante em que o ScaffoldMessenger dispensa a barra — mesmo timer
/// lógico, mesma duração).
class _CountdownContent extends StatefulWidget {
  const _CountdownContent({required this.message, required this.duration});

  final String message;
  final Duration duration;

  @override
  State<_CountdownContent> createState() => _CountdownContentState();
}

class _CountdownContentState extends State<_CountdownContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    // 1.0 → 0.0: o tempo restante "derrete" ao longo dos 4s.
    _controller.reverse(from: 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Cor auditada do tema (≥ 4.5:1 sobre o fundo da barra nos DOIS
    // brilhos) — com fallback do esquema para hosts sem snackBarTheme.
    final progressColor =
        theme.snackBarTheme.actionTextColor ?? theme.colorScheme.inversePrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.message),
        const SizedBox(height: 8),
        // RepaintBoundary: só a linha de 3px redesenha a cada tick do
        // countdown (a mensagem e a ação ficam estáticas).
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => LinearProgressIndicator(
              value: _controller.value,
              minHeight: 3,
              borderRadius: BorderRadius.circular(1.5),
              backgroundColor: progressColor.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
        ),
      ],
    );
  }
}
