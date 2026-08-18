import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Viewport RETRATO padrão dos testes de rotação (400×1400).
///
/// Estreito porém alto: garante que o conteúdo seja construído/pintado
/// abaixo do fold (overflow ficaria mascarado em telas baixas) e que o
/// layout de coluna estreita seja exercitado antes do giro.
const portraitViewportSize = Size(400, 1400);

/// Viewport PAISAGEM padrão dos testes de rotação (800×600).
const landscapeViewportSize = Size(800, 600);

/// Aplica o viewport de retrato padrão (400×1400, DPR 1.0) e registra o
/// reset automático no tearDown.
///
/// Sempre a primeira chamada de um teste de rotação: monta a tela em
/// retrato, verifica o layout estreito e só então gira.
void usePortraitViewport(WidgetTester tester) {
 tester.view.physicalSize = portraitViewportSize;
 tester.view.devicePixelRatio = 1.0;
 addTearDown(tester.view.reset);
}

/// Gira o viewport para paisagem (800×600 por padrão) e espera a re-layout.
///
/// [size] permite um limiar específico — ex.: 1280×800 para o teste do
/// NavigationRail do AppShell (>= 880px).
Future<void> rotateToLandscape(
 WidgetTester tester, {
 Size size = landscapeViewportSize,
}) async {
 tester.view.physicalSize = size;
 await tester.pumpAndSettle();
}
