import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/daily_pass_offer.dart';
import '../models/gym.dart';
import '../models/one_time_payment.dart';
import '../models/user_account.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/credit_card_brand.dart';
import '../utils/payment_input_formatters.dart';
import '../widgets/connect_primary_button.dart';
import '../widgets/credit_card_number_field.dart';
import 'purchase_success_screen.dart';

class DailyPassCheckoutScreen extends StatefulWidget {
  const DailyPassCheckoutScreen({
    super.key,
    required this.gym,
    required this.offer,
  });

  final Gym gym;
  final DailyPassOffer offer;

  @override
  State<DailyPassCheckoutScreen> createState() => _DailyPassCheckoutScreenState();
}

class _DailyPassCheckoutScreenState extends State<DailyPassCheckoutScreen> {
  OneTimePaymentMethod _method = OneTimePaymentMethod.pix;
  CreditCheckoutMode _creditMode = CreditCheckoutMode.savedCard;
  String? _selectedCardId;
  bool _submitting = false;
  CreditCardBrand _cardBrand = CreditCardBrand.unknown;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickDefaultCard());
  }

  void _pickDefaultCard() {
    final cards = context.read<AppState>().savedCards;
    if (cards.isEmpty) {
      setState(() => _creditMode = CreditCheckoutMode.newCard);
      return;
    }
    final def = cards.where((c) => c.isDefault).firstOrNull ?? cards.first;
    setState(() {
      _selectedCardId = def.id;
      _creditMode = CreditCheckoutMode.savedCard;
    });
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
    final cards = context.watch<AppState>().savedCards;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Pagamento da diária')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.pageX, 8, AppSpacing.pageX, 120),
        children: [
          Text('Checkout', style: AppTypography.sectionTitle),
          const SizedBox(height: 6),
          Text(
            'Escolha PIX ou cartão. Você também pode usar um cartão já cadastrado ou Apple Pay.',
            style: AppTypography.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.block),
          _DailySummaryCard(gym: widget.gym, offer: widget.offer),
          const SizedBox(height: AppSpacing.section),
          Text('Forma de pagamento', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.item),
          _MethodPicker(
            method: _method,
            onChanged: (m) => setState(() => _method = m),
          ),
          const SizedBox(height: AppSpacing.block),
          if (_method == OneTimePaymentMethod.pix) ...[
            _PixPanel(amount: widget.offer.price),
          ] else ...[
            if (cards.isNotEmpty) ...[
              Text('Cartões na sua carteira', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              ...cards.map((card) => _SavedCardTile(
                    card: card,
                    selected: _method == OneTimePaymentMethod.creditCard &&
                        _creditMode == CreditCheckoutMode.savedCard &&
                        _selectedCardId == card.id,
                    onTap: () => setState(() {
                      _method = OneTimePaymentMethod.creditCard;
                      _creditMode = CreditCheckoutMode.savedCard;
                      _selectedCardId = card.id;
                    }),
                  )),
              const SizedBox(height: AppSpacing.item),
            ],
            _ApplePayTile(
              selected: _method == OneTimePaymentMethod.applePay,
              onTap: () => setState(() => _method = OneTimePaymentMethod.applePay),
            ),
            const SizedBox(height: AppSpacing.item),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _method = OneTimePaymentMethod.creditCard;
                _creditMode = CreditCheckoutMode.newCard;
                _selectedCardId = null;
              }),
              icon: const Icon(Icons.add_card_rounded, size: 20),
              label: const Text('Pagar com outro cartão de crédito'),
            ),
            if (_method == OneTimePaymentMethod.creditCard &&
                _creditMode == CreditCheckoutMode.newCard) ...[
              const SizedBox(height: AppSpacing.block),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _fieldDecoration('Nome no cartão'),
                      validator: (v) =>
                          v == null || v.trim().length < 3 ? 'Informe o titular' : null,
                    ),
                    const SizedBox(height: AppSpacing.item),
                    CreditCardNumberField(
                      controller: _numberController,
                      decoration: _fieldDecoration('Número do cartão', prefix: Icons.credit_card_rounded),
                      onBrandChanged: (b) {
                        if (_cardBrand != b) setState(() => _cardBrand = b);
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
                              CardExpiryInputFormatter(),
                            ],
                            decoration: _fieldDecoration('Validade (MM/AA)'),
                            validator: (v) => paymentDigitsOnly(v).length != 4 ? 'MM/AA' : null,
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
                              LengthLimitingTextInputFormatter(specForBrand(_cardBrand).cvvLength),
                            ],
                            decoration: _fieldDecoration('CVV'),
                            validator: (v) {
                              final need = specForBrand(_cardBrand).cvvLength;
                              if (v == null || v.length < need) return 'CVV';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
      bottomNavigationBar: ConnectStickyActions(
        children: [
          ConnectPrimaryButton(
            label: _submitLabel,
            icon: _submitIcon,
            onPressed: _submitting ? null : _pay,
          ),
        ],
      ),
    );
  }

  String get _submitLabel {
    if (_submitting) return 'Processando…';
    return switch (_method) {
      OneTimePaymentMethod.pix => 'Gerar PIX e confirmar',
      OneTimePaymentMethod.applePay => 'Pagar com Apple Pay',
      OneTimePaymentMethod.creditCard => 'Pagar com cartão',
    };
  }

  IconData get _submitIcon {
    return switch (_method) {
      OneTimePaymentMethod.pix => Icons.pix_rounded,
      OneTimePaymentMethod.applePay => Icons.phone_iphone_rounded,
      OneTimePaymentMethod.creditCard => Icons.lock_rounded,
    };
  }

  Future<void> _pay() async {
    if (_method == OneTimePaymentMethod.creditCard &&
        _creditMode == CreditCheckoutMode.newCard) {
      if (!_formKey.currentState!.validate()) return;
    }

    if (_method == OneTimePaymentMethod.creditCard &&
        _creditMode == CreditCheckoutMode.savedCard &&
        _selectedCardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um cartão cadastrado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    final appState = context.read<AppState>();
    String paymentLabel;
    String? cardBrand;
    String? cardLastFour;

    switch (_method) {
      case OneTimePaymentMethod.pix:
        paymentLabel = 'PIX';
        break;
      case OneTimePaymentMethod.applePay:
        paymentLabel = 'Apple Pay';
        cardBrand = 'Apple Pay';
        cardLastFour = '••••';
        break;
      case OneTimePaymentMethod.creditCard:
        if (_creditMode == CreditCheckoutMode.savedCard) {
          final card = appState.savedCards.firstWhere((c) => c.id == _selectedCardId);
          paymentLabel = '${card.brand} final ${card.lastFour}';
          cardBrand = card.brand;
          cardLastFour = card.lastFour;
        } else {
          final digits = paymentDigitsOnly(_numberController.text);
          cardBrand = inferCardBrand(digits);
          cardLastFour = digits.substring(digits.length - 4);
          paymentLabel = '$cardBrand final $cardLastFour';
          appState.registerPaymentCard(
            brand: cardBrand,
            lastFour: cardLastFour,
            holderName: _nameController.text.trim(),
            expiryLabel: _expiryController.text.trim(),
          );
        }
    }

    final ok = await appState.addDailyPass(
      gym: widget.gym,
      offer: widget.offer,
      paymentLabel: paymentLabel,
      cardLastFour: cardLastFour,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pagamento simulado, mas não foi possível registrar a diária na academia. '
            'Verifique que a API está rodando e tente novamente.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => PurchaseSuccessScreen(
          gym: widget.gym,
          type: PurchaseType.dailyPass,
        ),
      ),
      (route) => route.isFirst,
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
}

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({required this.gym, required this.offer});

  final Gym gym;
  final DailyPassOffer offer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(offer.label, style: AppTypography.caption),
            const SizedBox(height: 4),
            Text(gym.name, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
            Text(gym.unitLabel, style: AppTypography.bodyMuted),
            const SizedBox(height: 8),
            Text(
              'R\$ ${offer.price.toStringAsFixed(2)}',
              style: AppTypography.pageTitle.copyWith(fontSize: 22, color: AppColors.orange),
            ),
            Text(offer.validityLabel, style: AppTypography.bodyMuted.copyWith(fontSize: 13)),
            const SizedBox(height: 8),
            Text(
              'Modalidades: ${offer.modalitiesSummary}',
              style: AppTypography.bodyMuted.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodPicker extends StatelessWidget {
  const _MethodPicker({required this.method, required this.onChanged});

  final OneTimePaymentMethod method;
  final ValueChanged<OneTimePaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MethodChip(
            label: 'PIX',
            icon: Icons.pix_rounded,
            selected: method == OneTimePaymentMethod.pix,
            onTap: () => onChanged(OneTimePaymentMethod.pix),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MethodChip(
            label: 'Cartão',
            icon: Icons.credit_card_rounded,
            selected: method == OneTimePaymentMethod.creditCard ||
                method == OneTimePaymentMethod.applePay,
            onTap: () => onChanged(OneTimePaymentMethod.creditCard),
          ),
        ),
      ],
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.orangeSoft : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.orange : AppColors.border, width: selected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: selected ? AppColors.orangeDark : AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.cardTitle.copyWith(
                  fontSize: 14,
                  color: selected ? AppColors.orangeDark : AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PixPanel extends StatelessWidget {
  const _PixPanel({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.qr_code_2_rounded, size: 100, color: AppColors.foreground),
          ),
          const SizedBox(height: 12),
          Text('PIX copia e cola', style: AppTypography.caption),
          const SizedBox(height: 8),
          SelectableText(
            '00020126580014BR.GOV.BCB.PIX0136acaf-${amount.toStringAsFixed(2)}',
            style: AppTypography.bodyMuted.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ao confirmar, simulamos a aprovação instantânea do PIX.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMuted.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SavedCardTile extends StatelessWidget {
  const _SavedCardTile({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  final SavedPaymentCard card;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.orange : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? AppColors.orange : AppColors.textMuted,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${card.brand} · ${card.maskedNumber}', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                      Text('${card.holderName} · val. ${card.expiryLabel}', style: AppTypography.caption),
                    ],
                  ),
                ),
                if (card.isDefault)
                  Text('Principal', style: AppTypography.label.copyWith(color: AppColors.orangeDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplePayTile extends StatelessWidget {
  const _ApplePayTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.orange : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.apple, color: Colors.white, size: 22),
              const SizedBox(width: 6),
              Text(
                'Pay',
                style: AppTypography.cardTitle.copyWith(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
