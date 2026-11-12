import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/api_config.dart';

import 'data/associates_repository.dart';
import 'data/connect_domain.dart';
import 'screens/home_shell.dart';
import 'state/app_state.dart';
import 'state/catalog_state.dart';
import 'state/location_state.dart';
import 'state/app_state_persistence.dart';
import 'branding/movly_brand.dart';
import 'theme/app_colors.dart';
import 'theme/movly_theme.dart';
import 'widgets/brand_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final catalogState = CatalogState();
  final locationState = LocationState(catalogState);
  catalogState.addListener(() {
    if (catalogState.isReady) {
      locationState.refreshDistancesFromCache();
    }
  });
  String? bootstrapError;

  try {
    await ConnectDomain.load();
    await catalogState.load();
  } catch (e) {
    bootstrapError = e is StateError ? e.message : 'Não foi possível conectar à API.';
  }

  final associatesRepository = AssociatesRepository(catalogState);
  final persistence = AppStatePersistence(repository: associatesRepository);
  final appState = AppState(
    persistence: persistence,
    associatesRepository: associatesRepository,
  );
  await appState.loadPersistedState();

  locationState.resolveNearbyArea();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: catalogState),
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: locationState),
      ],
      child: MovlyApp(bootstrapError: bootstrapError),
    ),
  );
}

class MovlyApp extends StatelessWidget {
  const MovlyApp({super.key, this.bootstrapError});

  final String? bootstrapError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: MovlyBrand.materialAppTitle,
      debugShowCheckedModeBanner: false,
      theme: MovlyTheme.light(),
      home: bootstrapError != null
          ? ApiBootstrapErrorScreen(message: bootstrapError!)
          : const HomeShell(),
    );
  }
}

class ApiBootstrapErrorScreen extends StatelessWidget {
  const ApiBootstrapErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandLogo(height: 40),
              const SizedBox(height: 24),
              Text(
                'Não foi possível iniciar',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(message, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(
                kReleaseMode
                    ? 'Verifique sua conexão com a internet e tente novamente. '
                        'API: ${ApiConfig.productionBaseUrl}'
                    : 'Em desenvolvimento, verifique que a API está rodando em '
                        'http://127.0.0.1:8787 (Android emulador: http://10.0.2.2:8787). '
                        'Para testar produção: flutter run --dart-define=CONNECT_API_URL=${ApiConfig.productionBaseUrl}',
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const BootstrapRetryScreen(),
                    ),
                  );
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BootstrapRetryScreen extends StatefulWidget {
  const BootstrapRetryScreen({super.key});

  @override
  State<BootstrapRetryScreen> createState() => _BootstrapRetryScreenState();
}

class _BootstrapRetryScreenState extends State<BootstrapRetryScreen> {
  @override
  void initState() {
    super.initState();
    _retry();
  }

  Future<void> _retry() async {
    final catalog = context.read<CatalogState>();
    try {
      await ConnectDomain.load();
      await catalog.load();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeShell()),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ApiBootstrapErrorScreen(
            message: e is StateError ? e.message : 'Falha ao conectar à API.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
