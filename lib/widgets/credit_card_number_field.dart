import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/credit_card_brand.dart';
import '../utils/payment_input_formatters.dart';

class CreditCardNumberField extends StatefulWidget {
  const CreditCardNumberField({
    super.key,
    required this.controller,
    required this.decoration,
    this.onBrandChanged,
    this.validator,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final ValueChanged<CreditCardBrand>? onBrandChanged;
  final FormFieldValidator<String>? validator;

  @override
  State<CreditCardNumberField> createState() => _CreditCardNumberFieldState();
}

class _CreditCardNumberFieldState extends State<CreditCardNumberField> {
  CreditCardBrand _brand = CreditCardBrand.unknown;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncBrandFromController);
    _syncBrandFromController();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncBrandFromController);
    super.dispose();
  }

  void _syncBrandFromController() {
    final digits = paymentDigitsOnly(widget.controller.text);
    final next = detectCreditCardBrand(digits);
    if (next != _brand) {
      setState(() => _brand = next);
      widget.onBrandChanged?.call(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = specForBrand(_brand);
    final suffix = _brand == CreditCardBrand.unknown
        ? widget.decoration.suffixIcon
        : Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              widthFactor: 1,
              child: _BrandBadge(spec: spec),
            ),
          );

    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.number,
      inputFormatters: const [CardNumberInputFormatter()],
      decoration: widget.decoration.copyWith(
        prefixIcon: widget.decoration.prefixIcon ??
            const Icon(Icons.credit_card_rounded, color: AppColors.textMuted, size: 22),
        suffixIcon: suffix,
        suffixIconConstraints: _brand == CreditCardBrand.unknown
            ? widget.decoration.suffixIconConstraints
            : const BoxConstraints(minWidth: 56, minHeight: 32),
      ),
      validator: widget.validator ??
          (v) => validateCardNumberDigits(paymentDigitsOnly(v)),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({required this.spec});

  final CreditCardBrandSpec spec;

  @override
  Widget build(BuildContext context) {
    final label = spec.shortLabel ?? spec.displayName;
    final color = spec.accentColorArgb != null
        ? Color(spec.accentColorArgb!)
        : AppColors.textMuted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: color,
          ),
        ),
      ),
    );
  }
}
