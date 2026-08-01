import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/connect_plans.dart';
import '../models/connect_product_plan.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/connect_primary_button.dart';
import 'connect_plan_checkout_success_screen.dart';

class ConnectPlanCheckoutScreen extends StatefulWidget {
  const ConnectPlanCheckoutScreen({super.key, required this.planId});

  final String planId;

  @override
  State<ConnectPlanCheckoutScreen> createState() => _ConnectPlanCheckoutScreenState();
}

class _ConnectPlanCheckoutScreenState extends State<ConnectPlanCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _authorizeRecurring = false;
  bool _submitting = false;

  ConnectProductPlan get _plan {
    return connectPlanById(widget.planId) ?? connectProductPlans.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enrollment = context.watch<AppState>().companyEnrollment;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pageX, 8, AppSpacing.pageX, 120),
          children: [
            Text('Pagamento recorrente', style: AppTypography.sectionTitle),
            const SizedBox(height: 6),
            Text(
              'Cadastre seu cartão para débito automático mensal do plano ACAF Connect.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.block),
            _PlanSummaryCard(plan: _plan, companyName: enrollment?.companyName),
            const SizedBox(height: AppSpacing.section),
            Text('Cartão de crédito', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.item),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDecoration('Nome impresso no cartão'),
              validator: (v) {
                if (v == null || v.trim().length < 3) {
                  return 'Informe o nome do titular';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.item),
            TextFormField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                _CardNumberFormatter(),
              ],
              decoration: _fieldDecoration('Número do cartão', prefix: Icons.credit_card_rounded),
              validator: (v) {
                final digits = _digitsOnly(v);
                if (digits.length < 16) return 'Informe os 16 dígitos do cartão';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.item),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryFormatter(),
                    ],
                    decoration: _fieldDecoration('Validade (MM/AA)'),
                    validator: (v) {
                      final d = _digitsOnly(v);
                      if (d.length != 4) return 'MM/AA';
                      final month = int.tryParse(d.substring(0, 2));
                      if (month == null || month < 1 || month > 12) return 'Mês inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.item),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: _fieldDecoration('CVV'),
                    validator: (v) {
                      if (v == null || v.length < 3) return 'CVV inválido';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.block),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cobrança mensal', style: AppTypography.caption.copyWith(color: AppColors.foreground)),
                  const SizedBox(height: 8),
                  Text(
                    'Serão debitados R\$ ${_plan.pricePerMonth.toStringAsFixed(2)} por mês até você cancelar. '
                    'A primeira cobrança ocorre hoje; as próximas no mesmo dia de cada mês.',
                    style: AppTypography.bodyMuted.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.item),
            CheckboxListTile(
              value: _authorizeRecurring,
              onChanged: _submitting ? null : (v) => setState(() => _authorizeRecurring = v ?? false),
              activeColor: AppColors.orange,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Autorizo o débito recorrente mensal no cartão acima, conforme o plano escolhido.',
                style: AppTypography.bodyMuted.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ConnectStickyActions(
        children: [
          ConnectPrimaryButton(
            label: _submitting
                ? 'Cadastrando cartão…'
                : 'Cadastrar cartão e assinar',
            icon: Icons.lock_rounded,
            onPressed: _submitting || !_authorizeRecurring ? null : () => _submit(context),
          ),
          if (!_authorizeRecurring)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Marque a autorização de débito recorrente para continuar.',
                textAlign: TextAlign.center,
                style: AppTypography.caption,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, {IconData? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefix != null ? Icon(prefix, color: AppColors.textMuted, size: 22) : null,
      filled: true,
      fillColor: AppColors.surfaceMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!context.mounted) return;

    final digits = _digitsOnly(_numberController.text);
    final brand = _inferCardBrand(digits);
    final lastFour = digits.substring(digits.length - 4);

    context.read<AppState>().activateConnectPlan(
          planId: _plan.id,
          cardBrand: brand,
          cardLastFour: lastFour,
          holderName: _nameController.text.trim(),
          expiryLabel: _expiryController.text.trim(),
        );

    if (!context.mounted) return;
    setState(() => _submitting = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ConnectPlanCheckoutSuccessScreen(plan: _plan, cardBrand: brand, cardLastFour: lastFour),
      ),
    );
  }

  static String _digitsOnly(String? value) => value?.replaceAll(RegExp(r'\D'), '') ?? '';

  static String _inferCardBrand(String digits) {
    if (digits.startsWith('4')) return 'Visa';
    if (digits.startsWith('5')) return 'Mastercard';
    if (digits.startsWith('3')) return 'Amex';
    return 'Cartão';
  }
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({required this.plan, this.companyName});

  final ConnectProductPlan plan;
  final String? companyName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.name, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'R\$ ${plan.pricePerMonth.toStringAsFixed(2)}/mês',
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.orange),
            ),
            const SizedBox(height: 8),
            Text('1 check-in por dia · Rede ACAF Connect', style: AppTypography.bodyMuted.copyWith(fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              'Modalidades conforme configuração de cada unidade visitada.',
              style: AppTypography.bodyMuted.copyWith(fontSize: 13),
            ),
            if (companyName != null) ...[
              const SizedBox(height: 8),
              Text('Empresa: $companyName', style: AppTypography.caption),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    if (digits.length <= 2) {
      return TextEditingValue(text: digits, selection: TextSelection.collapsed(offset: digits.length));
    }
    final text = '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
