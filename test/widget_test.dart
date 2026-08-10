import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acaf/main.dart';

void main() {
  testWidgets('mostra erro quando API não está disponível no bootstrap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ApiBootstrapErrorScreen(message: 'Não foi possível conectar à API local.'),
      ),
    );

    expect(find.text('Não foi possível iniciar'), findsOneWidget);
    expect(find.textContaining('127.0.0.1:8787'), findsOneWidget);
  });
}
