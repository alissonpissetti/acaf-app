import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/associates_repository.dart';
import 'screens/api_bootstrap_error_screen.dart';
import 'screens/app_launch_splash_screen.dart';
import 'screens/home_shell.dart';
import 'state/app_state.dart';
import 'state/catalog_state.dart';
import 'state/location_state.dart';
import 'state/app_state_persistence.dart';
import 'branding/movly_brand.dart';
import 'theme/movly_theme.dart';
import 'services/biometric_auth_service.dart';
import 'widgets/app_entry_gate.dart';
import 'widgets/biometric_unlock_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final catalogState = CatalogState();
  final locationState = LocationState(catalogState);
  catalogState.addListener(() {
    if (catalogState.isReady) {
      locationState.refreshDistancesFromCache();
    }
  });
  final associatesRepository = AssociatesRepository(catalogState);
  final persistence = AppStatePersistence(repository: associatesRepository);
  final biometricAuth = BiometricAuthService();
  final appState = AppState(
    persistence: persistence,
    associatesRepository: associatesRepository,
    biometricSessionStore: biometricAuth.sessionStore,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: catalogState),
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: locationState),
        Provider.value(value: biometricAuth),
      ],
      child: MovlyApp(biometricAuth: biometricAuth),
    ),
  );
}

class MovlyApp extends StatefulWidget {
  const MovlyApp({super.key, required this.biometricAuth});

  final BiometricAuthService biometricAuth;

  @override
  State<MovlyApp> createState() => _MovlyAppState();
}

class _MovlyAppState extends State<MovlyApp> {
  bool _bootstrapFinished = false;
  String? _bootstrapError;

  void _onBootstrapComplete(String? error) {
    setState(() {
      _bootstrapError = error;
      _bootstrapFinished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: MovlyBrand.materialAppTitle,
      debugShowCheckedModeBanner: false,
      theme: MovlyTheme.light(),
      home: !_bootstrapFinished
          ? AppLaunchSplashScreen(onBootstrapComplete: _onBootstrapComplete)
          : _bootstrapError != null
              ? ApiBootstrapErrorScreen(message: _bootstrapError!)
              : BiometricUnlockGate(
                  biometricAuth: widget.biometricAuth,
                  child: const AppEntryGate(child: HomeShell()),
                ),
    );
  }
}
