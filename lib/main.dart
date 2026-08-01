import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'state/app_state.dart';
import 'state/location_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.loadPersistedState();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider(
          create: (_) => LocationState()..resolveNearbyArea(),
        ),
      ],
      child: const AcafApp(),
    ),
  );
}

class AcafApp extends StatelessWidget {
  const AcafApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ACAF Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeShell(),
    );
  }
}
