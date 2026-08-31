import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/connect_bottom_nav.dart';
import '../widgets/connect_page_header.dart';
import '../widgets/connect_primary_button.dart';

/// Onboarding: colaborador informa o código de adesão da empresa.
class CompanyEnrollmentOnboarding extends StatefulWidget {
  const CompanyEnrollmentOnboarding({super.key});

  @override
  State<CompanyEnrollmentOnboarding> createState() => _CompanyEnrollmentOnboardingState();
}

class _CompanyEnrollmentOnboardingState extends State<CompanyEnrollmentOnboarding> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  String? _error;
  bool _loading = false;
  int _step = 0;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    final err = await context.read<AppState>().redeemEnrollmentCode(
          _codeController.text,
          collaboratorName: _nameController.text,
        );

    if (!mounted) return;

    setState(() => _loading = false);

    if (err != null) {
      setState(() => _error = err);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código validado. Agora escolha seu plano.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ConnectPageHeader(
          title: 'Minha conta',
          subtitle: 'Cadastre-se com o código de adesão da sua empresa.',
        ),
        Expanded(
          child: ListView(
            padding: ConnectBottomNav.listPadding(context, top: 20),
            children: [
              _StepIndicator(current: _step),
              const SizedBox(height: AppSpacing.block),
              if (_step == 0) ...[
                _InfoCard(
                  icon: Icons.business_center_rounded,
                  title: 'Benefício corporativo',
                  body:
                      'Sua empresa liberou o benefício. '
                      'Use o código de adesão compartilhado pelo RH para vincular sua empresa.',
                ),
                const SizedBox(height: AppSpacing.block),
                _InfoCard(
                  icon: Icons.vpn_key_rounded,
                  title: 'Código de adesão',
                  body:
                      'É um código único da empresa (ex.: TAGSA). '
                      'Sem ele, não é possível escolher o plano corporativo.',
                ),
                const SizedBox(height: AppSpacing.section),
                ConnectPrimaryButton(
                  label: 'Tenho meu código',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => setState(() => _step = 1),
                ),
              ] else ...[
                Text('Identificação', style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.tight),
                Text(
                  'Informe o código liberado pela sua empresa.',
                  style: AppTypography.bodyMuted,
                ),
                const SizedBox(height: AppSpacing.block),
                Text('Código de adesão', style: AppTypography.label.copyWith(color: AppColors.foregroundSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'Ex.: TAGSA',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.item),
                Text('Seu nome (opcional)', style: AppTypography.label.copyWith(color: AppColors.foregroundSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Como no cadastro do RH',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.item),
                  Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.error)),
                ],
                const SizedBox(height: AppSpacing.block),
                ConnectPrimaryButton(
                  label: _loading ? 'Validando...' : 'Validar e continuar',
                  icon: Icons.verified_rounded,
                  onPressed: _loading ? () {} : _submitCode,
                ),
                const SizedBox(height: AppSpacing.item),
                TextButton(
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('Voltar'),
                ),
                const SizedBox(height: AppSpacing.section),
                Text('Onde achar o código?', style: AppTypography.label),
                const SizedBox(height: AppSpacing.tight),
                Text(
                  'E-mail do RH, portal corporativo ou mensagem com o código da empresa.',
                  style: AppTypography.bodyMuted,
                ),
                const SizedBox(height: AppSpacing.tight),
                Text(
                  'Use o código enviado pelo RH da sua empresa.',
                  style: AppTypography.caption,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(active: current >= 0, label: '1', title: 'Empresa'),
        Expanded(child: Container(height: 2, color: AppColors.border)),
        _StepDot(active: current >= 1, label: '2', title: 'Código'),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.active, required this.label, required this.title});

  final bool active;
  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: active ? AppColors.orange : AppColors.surfaceMuted,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: active ? Colors.white : AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: AppTypography.caption),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.orangeSoft,
              child: Icon(icon, size: 20, color: AppColors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(body, style: AppTypography.bodyMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
