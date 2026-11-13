import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pending_company_code_store.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'company_code_entry_sheet.dart';
import 'connect_primary_button.dart';

/// Após splash e biometria: modal de código (se necessário) e banner no modo guia.
class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  bool _entryFlowDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runEntryFlow());
  }

  Future<void> _runEntryFlow() async {
    final appState = context.read<AppState>();

    if (!mounted) return;

    if (!appState.shouldShowCompanyCodeEntry) {
      setState(() => _entryFlowDone = true);
      return;
    }

    final choice = await showCompanyCodeEntrySheet(context);
    if (!mounted) return;

    await appState.completeCompanyCodeEntry(choice);
    if (!mounted) return;

    if (choice == CompanyCodeEntryChoice.openEnrollment) {
      await openCompanyEnrollmentFlow(context);
    }

    if (!mounted) return;
    setState(() => _entryFlowDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_entryFlowDone) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isGuest = context.watch<AppState>().isGuestGuideMode;
    if (!isGuest) {
      return widget.child;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GuestGuideBanner(),
        Expanded(child: widget.child),
      ],
    );
  }
}

class _GuestGuideBanner extends StatelessWidget {
  const _GuestGuideBanner();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final hasPending = appState.pendingCompanyCode != null;

    return Material(
      color: AppColors.purpleSoft,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pageX, 10, AppSpacing.pageX, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Modo guia',
                style: AppTypography.label.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                hasPending
                    ? 'Código salvo. Conclua o cadastro para comprar planos e usar sua conta.'
                    : 'Explore academias livremente. Para benefício corporativo, informe o código da empresa.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 10),
              ConnectPrimaryButton(
                label: hasPending ? 'Concluir cadastro' : 'Cadastrar com código da empresa',
                icon: Icons.vpn_key_rounded,
                onPressed: () => openCompanyEnrollmentFlow(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
