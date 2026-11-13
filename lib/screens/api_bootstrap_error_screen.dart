import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../data/connect_domain.dart';
import '../state/catalog_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_entry_gate.dart';
import '../widgets/biometric_unlock_gate.dart';
import '../widgets/brand_logo.dart';
import '../services/biometric_auth_service.dart';
import 'home_shell.dart';

/// Exibida quando o bootstrap falha ao carregar o domínio Movly / catálogo.
class ApiBootstrapErrorScreen extends StatefulWidget {
  const ApiBootstrapErrorScreen({super.key, required this.message});

  /// Mensagem técnica (só visível em modo desenvolvimento).
  final String message;

  @override
  State<ApiBootstrapErrorScreen> createState() =>
      _ApiBootstrapErrorScreenState();
}

class _ApiBootstrapErrorScreenState extends State<ApiBootstrapErrorScreen> {
  bool _devDetailsExpanded = false;

  static const _title = 'Não conseguimos conectar agora';
  static const _body =
      'O app não conseguiu se preparar para uso. '
      'Confira se você está online e tente de novo em alguns instantes.';
  static const _supportHint =
      'Se o problema continuar, fale com o suporte da sua academia ou da ACAF.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).top -
                  MediaQuery.paddingOf(context).bottom -
                  32,
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: BrandLogo(height: 40),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: AppColors.primary.withValues(alpha: 0.85),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _title,
                        style: AppTypography.pageTitle.copyWith(fontSize: 22),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _body,
                        style: AppTypography.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _supportHint,
                        style: AppTypography.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  _DevDiagnosticsPanel(
                    message: widget.message,
                    expanded: _devDetailsExpanded,
                    onExpansionChanged: (open) =>
                        setState(() => _devDetailsExpanded = open),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Tentar novamente'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manter o Wi‑Fi ou os dados móveis ativos ajuda na próxima tentativa.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onRetry() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => const BootstrapRetryScreen(),
      ),
    );
  }
}

class _DevDiagnosticsPanel extends StatelessWidget {
  const _DevDiagnosticsPanel({
    required this.message,
    required this.expanded,
    required this.onExpansionChanged,
  });

  final String message;
  final bool expanded;
  final void Function(bool) onExpansionChanged;

  String get _devDetailsText {
    final baseUrl = ApiConfig.resolveBaseUrl();
    final productionHint =
        'Produção: flutter run --dart-define=CONNECT_API_URL=${ApiConfig.productionBaseUrl}';
    return [
      'Detalhe: $message',
      'URL da API: $baseUrl',
      'Local: API em http://127.0.0.1:${ApiConfig.defaultPort}',
      'Android emulador: http://10.0.2.2:${ApiConfig.defaultPort}',
      productionHint,
    ].join('\n');
  }

  Future<void> _copyDetails(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _devDetailsText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detalhes copiados'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSunken,
      borderRadius: BorderRadius.circular(14),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Text(
            'Detalhes para desenvolvimento',
            style: AppTypography.cardTitle.copyWith(fontSize: 14),
          ),
          subtitle: Text(
            'Mensagem técnica, URLs e dicas locais',
            style: AppTypography.caption,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                _devDetailsText,
                style: AppTypography.caption.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _copyDetails(context),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copiar detalhes'),
              ),
            ),
          ],
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
      final biometricAuth = context.read<BiometricAuthService>();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BiometricUnlockGate(
            biometricAuth: biometricAuth,
            child: const AppEntryGate(child: HomeShell()),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ApiBootstrapErrorScreen(
            message: e is StateError ? e.message : 'Falha ao contactar a API.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
