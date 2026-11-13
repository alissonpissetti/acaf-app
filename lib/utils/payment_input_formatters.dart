import 'package:flutter/services.dart';

import 'credit_card_brand.dart';

class CardNumberInputFormatter extends TextInputFormatter {
  const CardNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final brand = detectCreditCardBrand(digits);
    final spec = specForBrand(brand);
    final maxLen = brand == CreditCardBrand.unknown ? 19 : spec.maxDigits;
    final truncated = digits.length > maxLen ? digits.substring(0, maxLen) : digits;
    final text = formatCardNumberDigits(truncated, brand);

    final selectionIndex = _resolveSelection(
      oldValue: oldValue,
      newValue: newValue,
      formatted: text,
      truncatedDigits: truncated,
    );

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }

  int _resolveSelection({
    required TextEditingValue oldValue,
    required TextEditingValue newValue,
    required String formatted,
    required String truncatedDigits,
  }) {
    final newDigitCount = truncatedDigits.length;
    final oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    final isDeletion = newDigitCount < oldDigits.length;

    if (isDeletion && newValue.selection.baseOffset < newValue.text.length) {
      final digitsBeforeCursor =
          newValue.text.substring(0, newValue.selection.baseOffset).replaceAll(RegExp(r'\D'), '').length;
      return _offsetForDigitIndex(formatted, digitsBeforeCursor);
    }

    if (!isDeletion) {
      return _offsetForDigitIndex(formatted, newDigitCount);
    }

    return formatted.length;
  }

  int _offsetForDigitIndex(String formatted, int digitIndex) {
    if (digitIndex <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (formatted[i] != ' ') {
        seen++;
        if (seen >= digitIndex) return i + 1;
      }
    }
    return formatted.length;
  }
}

class CardExpiryInputFormatter extends TextInputFormatter {
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

String paymentDigitsOnly(String? value) => value?.replaceAll(RegExp(r'\D'), '') ?? '';

/// Máscara (XX) XXXXX-XXXX — celular BR com 11 dígitos.
class BrazilianMobileInputFormatter extends TextInputFormatter {
  const BrazilianMobileInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = paymentDigitsOnly(newValue.text);
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }
    final trimmed = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');
      buffer.write(trimmed[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

bool isValidBrazilianMobile(String? value) {
  final digits = paymentDigitsOnly(value);
  return digits.length == 11 && digits[2] == '9';
}

class CpfInputFormatter extends TextInputFormatter {
  const CpfInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = paymentDigitsOnly(newValue.text);
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }
    final trimmed = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(trimmed[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

String inferCardBrand(String digits) {
  return specForBrand(detectCreditCardBrand(digits)).displayName;
}
