import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pending_company_code_store.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../screens/company_enrollment_onboarding.dart';
import 'connect_primary_button.dart';

/// Modal/bottom sheet na primeira abertura sem sessão estabelecida.
Future<CompanyCodeEntryChoice?> showCompanyCodeEntrySheet(BuildContext context) {
  return showModalBottomSheet<CompanyCodeEntryChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.surface,
    builder: (ctx) => const _CompanyCodeEntrySheetBody(),
  );
}

class _CompanyCodeEntrySheetBody extends StatefulWidget {
  const _CompanyCodeEntrySheetBody();

  @override
  State<_CompanyCodeEntrySheetBody> createState() => _CompanyCodeEntrySheetBodyState();
}

class _CompanyCodeEntrySheetBodyState extends State<_CompanyCodeEntrySheetBody> {
  final _codeController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final pending = context.read<AppState>().pendingCompanyCode;
    if (pending != null && pending.isNotEmpty) {
      _codeController.text = pending;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _saveCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Informe o código da empresa.');
      return;
    }
    setState(() => _error = null);
    await context.read<AppState>().savePendingCompanyCode(code);
    if (!mounted) return;
    Navigator.of(context).pop(CompanyCodeEntryChoice.savedCode);
  }

  Future<void> _openEnrollment() async {
    final code = _codeController.text.trim();
    if (code.isNotEmpty) {
      await context.read<AppState>().savePendingCompanyCode(code);
    }
    if (!mounted) return;
    Navigator.of(context).pop(CompanyCodeEntryChoice.openEnrollment);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        8,
        AppSpacing.pageX,
        bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Código da empresa', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.tight),
            Text(
              'Se sua empresa oferece o benefício Movly, informe o código do RH. '
              'Você pode salvar agora e concluir o cadastro quando quiser.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.block),
            Text(
              'Código de acesso',
              style: AppTypography.label.copyWith(color: AppColors.foregroundSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'Ex.: CODIGODASUAEMPRESA',
                prefixIcon: Icon(Icons.business_rounded),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.tight),
              Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.block),
            ConnectPrimaryButton(
              label: 'Salvar código',
              icon: Icons.save_outlined,
              onPressed: _saveCode,
            ),
            const SizedBox(height: AppSpacing.item),
            ConnectPrimaryButton(
              label: 'Continuar cadastro',
              icon: Icons.verified_user_outlined,
              onPressed: _openEnrollment,
            ),
            const SizedBox(height: AppSpacing.tight),
            TextButton(
              onPressed: () => Navigator.of(context).pop(CompanyCodeEntryChoice.exploreOnly),
              child: const Text('Só explorar o guia de academias'),
            ),
            const SizedBox(height: AppSpacing.tight),
            Text(
              'Sem cadastro completo, você vê unidades e localização — sem compras nem conta.',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fluxo de cadastro em tela cheia (a partir do modal).
Future<void> openCompanyEnrollmentFlow(BuildContext context) {
  final initialCode = context.read<AppState>().pendingCompanyCode;
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: CompanyEnrollmentOnboarding(initialCode: initialCode),
        ),
      ),
    ),
  );
}
