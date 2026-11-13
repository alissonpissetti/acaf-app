import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acaf/screens/api_bootstrap_error_screen.dart';

void main() {
  testWidgets('mostra erro amigável quando API não está disponível no bootstrap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ApiBootstrapErrorScreen(message: 'Domínio Movly indisponível (fetchDomain sem dados).'),
      ),
    );

    expect(find.text('Não conseguimos conectar agora'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.textContaining('configuração da plataforma da API'), findsNothing);
    expect(find.textContaining('127.0.0.1:8787'), findsNothing);

    if (kDebugMode) {
      expect(find.text('Detalhes para desenvolvimento'), findsOneWidget);
      await tester.tap(find.text('Detalhes para desenvolvimento'));
      await tester.pumpAndSettle();
      expect(find.textContaining('127.0.0.1'), findsOneWidget);
    }
  });
}
