import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/connect_domain.dart';
import '../state/app_state.dart';
import '../state/catalog_state.dart';
import '../state/location_state.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_logo.dart';

/// Splash de abertura: marca visível por pelo menos [minDisplayDuration] enquanto o bootstrap roda.
class AppLaunchSplashScreen extends StatefulWidget {
  const AppLaunchSplashScreen({
    super.key,
    required this.onBootstrapComplete,
    this.minDisplayDuration = const Duration(milliseconds: 2500),
  });

  final void Function(String? bootstrapError) onBootstrapComplete;
  final Duration minDisplayDuration;

  @override
  State<AppLaunchSplashScreen> createState() => _AppLaunchSplashScreenState();
}

class _AppLaunchSplashScreenState extends State<AppLaunchSplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startBootstrap());
  }

  Future<void> _startBootstrap() async {
    final catalogState = context.read<CatalogState>();
    final appState = context.read<AppState>();
    final locationState = context.read<LocationState>();

    String? bootstrapError;

    Future<void> loadApp() async {
      try {
        await ConnectDomain.load();
        await catalogState.load();
        await appState.loadPersistedState();
        locationState.resolveNearbyArea();
      } catch (e) {
        bootstrapError = e is StateError ? e.message : 'Falha ao contactar a API.';
      }
    }

    await Future.wait<void>([
      Future<void>.delayed(widget.minDisplayDuration),
      loadApp(),
    ]);

    if (!mounted) return;
    widget.onBootstrapComplete(bootstrapError);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.movlyLime,
      body: Center(
        child: BrandLogo(height: 52, variant: BrandLogoVariant.purple),
      ),
    );
  }
}
