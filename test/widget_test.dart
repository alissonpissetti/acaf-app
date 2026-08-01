import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:acaf/main.dart';
import 'package:acaf/state/app_state.dart';
import 'package:acaf/state/location_state.dart';

void main() {
  testWidgets('lista associados ordenados por distância', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider(create: (_) => LocationState()),
        ],
        child: const AcafApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Carpe Diem Academia'), findsOneWidget);
    expect(find.textContaining('Unidade Portão'), findsOneWidget);
    expect(find.text('Mais perto'), findsOneWidget);
  });
}
