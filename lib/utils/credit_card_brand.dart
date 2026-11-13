/// Detecção de bandeira por BIN/prefixo, máscara e validação Luhn (apenas UX local;
/// tokenização PCI fica a cargo do gateway, ex. Asaas).
enum CreditCardBrand {
  visa,
  mastercard,
  amex,
  elo,
  hipercard,
  unknown,
}

class CreditCardBrandSpec {
  const CreditCardBrandSpec({
    required this.brand,
    required this.displayName,
    required this.maxDigits,
    required this.digitGroups,
    required this.cvvLength,
    this.shortLabel,
    this.accentColorArgb,
  });

  final CreditCardBrand brand;
  final String displayName;
  final int maxDigits;
  final List<int> digitGroups;
  final int cvvLength;
  final String? shortLabel;
  final int? accentColorArgb;
}

const _eloPrefix4 = <String>{
  '4011',
  '4312',
  '4389',
  '4514',
  '4573',
  '4576',
  '5041',
  '5066',
  '5067',
  '5090',
  '6277',
  '6362',
  '6363',
  '6504',
  '6505',
  '6516',
  '6550',
};

const _eloPrefix6 = <String>{
  '506699',
  '506700',
  '506701',
  '506702',
  '506703',
  '506704',
  '506705',
  '506706',
  '506707',
  '506708',
  '506709',
  '506710',
  '506711',
  '506712',
  '506713',
  '506714',
  '506715',
  '506716',
  '506717',
  '506718',
  '506719',
  '506720',
  '506721',
  '506722',
  '506723',
  '506724',
  '506725',
  '506726',
  '506727',
  '506728',
  '506729',
  '506730',
  '506731',
  '506732',
  '506733',
  '506734',
  '506735',
  '506736',
  '506737',
  '506738',
  '506739',
  '506740',
  '506741',
  '506742',
  '506743',
  '506744',
  '506745',
  '506746',
  '506747',
  '506748',
  '506749',
  '506750',
  '506751',
  '506752',
  '506753',
  '506754',
  '506755',
  '506756',
  '506757',
  '506758',
  '506759',
  '506760',
  '506761',
  '506762',
  '506763',
  '506764',
  '506765',
  '506766',
  '506767',
  '506768',
  '506769',
  '506770',
  '506771',
  '506772',
  '506773',
  '506774',
  '506775',
  '506776',
  '506777',
  '506778',
  '636368',
  '438935',
  '401178',
  '401179',
  '431274',
  '457631',
  '457632',
  '504175',
  '627780',
  '636297',
  '636369',
};

CreditCardBrandSpec specForBrand(CreditCardBrand brand) {
  return switch (brand) {
    CreditCardBrand.visa => const CreditCardBrandSpec(
        brand: CreditCardBrand.visa,
        displayName: 'Visa',
        shortLabel: 'VISA',
        maxDigits: 16,
        digitGroups: [4, 4, 4, 4],
        cvvLength: 3,
        accentColorArgb: 0xFF1A1F71,
      ),
    CreditCardBrand.mastercard => const CreditCardBrandSpec(
        brand: CreditCardBrand.mastercard,
        displayName: 'Mastercard',
        shortLabel: 'MC',
        maxDigits: 16,
        digitGroups: [4, 4, 4, 4],
        cvvLength: 3,
        accentColorArgb: 0xFFEB001B,
      ),
    CreditCardBrand.amex => const CreditCardBrandSpec(
        brand: CreditCardBrand.amex,
        displayName: 'Amex',
        shortLabel: 'AMEX',
        maxDigits: 15,
        digitGroups: [4, 6, 5],
        cvvLength: 4,
        accentColorArgb: 0xFF006FCF,
      ),
    CreditCardBrand.elo => const CreditCardBrandSpec(
        brand: CreditCardBrand.elo,
        displayName: 'Elo',
        shortLabel: 'ELO',
        maxDigits: 16,
        digitGroups: [4, 4, 4, 4],
        cvvLength: 3,
        accentColorArgb: 0xFF00A4E0,
      ),
    CreditCardBrand.hipercard => const CreditCardBrandSpec(
        brand: CreditCardBrand.hipercard,
        displayName: 'Hipercard',
        shortLabel: 'HIPER',
        maxDigits: 16,
        digitGroups: [4, 4, 4, 4],
        cvvLength: 3,
        accentColorArgb: 0xFFB3131B,
      ),
    CreditCardBrand.unknown => const CreditCardBrandSpec(
        brand: CreditCardBrand.unknown,
        displayName: 'Cartão',
        shortLabel: null,
        maxDigits: 19,
        digitGroups: [4, 4, 4, 4, 3],
        cvvLength: 3,
        accentColorArgb: null,
      ),
  };
}

/// Ordem: prefixos mais específicos (Elo/Hiper) antes de Visa/Master.
CreditCardBrand detectCreditCardBrand(String digits) {
  if (digits.isEmpty) return CreditCardBrand.unknown;

  if (digits.startsWith('606282') || digits.startsWith('3841')) {
    return CreditCardBrand.hipercard;
  }

  if (digits.length >= 6) {
    final six = digits.substring(0, 6);
    if (_eloPrefix6.contains(six)) return CreditCardBrand.elo;
  }
  if (digits.length >= 4) {
    final four = digits.substring(0, 4);
    if (_eloPrefix4.contains(four)) return CreditCardBrand.elo;
  }

  if (digits.startsWith('34') || digits.startsWith('37')) {
    return CreditCardBrand.amex;
  }

  if (digits.length >= 2) {
    final first2 = int.tryParse(digits.substring(0, 2));
    if (first2 != null && first2 >= 51 && first2 <= 55) {
      return CreditCardBrand.mastercard;
    }
  }
  if (digits.length >= 4) {
    final first4 = int.tryParse(digits.substring(0, 4));
    if (first4 != null && first4 >= 2221 && first4 <= 2720) {
      return CreditCardBrand.mastercard;
    }
  }

  if (digits.startsWith('4')) return CreditCardBrand.visa;

  return CreditCardBrand.unknown;
}

/// Agrupa dígitos conforme a bandeira (inclui truncamento no [maxDigits]).
String formatCardNumberDigits(String digits, CreditCardBrand brand) {
  final spec = specForBrand(brand);
  final effectiveBrand =
      brand == CreditCardBrand.unknown ? detectCreditCardBrand(digits) : brand;
  final effectiveSpec =
      effectiveBrand != CreditCardBrand.unknown ? specForBrand(effectiveBrand) : spec;

  var truncated = digits;
  if (truncated.length > effectiveSpec.maxDigits) {
    truncated = truncated.substring(0, effectiveSpec.maxDigits);
  }

  final buf = StringBuffer();
  var index = 0;
  for (final groupSize in effectiveSpec.digitGroups) {
    if (index >= truncated.length) break;
    if (buf.isNotEmpty) buf.write(' ');
    final end = (index + groupSize).clamp(0, truncated.length);
    buf.write(truncated.substring(index, end));
    index += groupSize;
  }
  if (index < truncated.length) {
    while (index < truncated.length) {
      buf.write(' ');
      final end = (index + 4).clamp(0, truncated.length);
      buf.write(truncated.substring(index, end));
      index += 4;
    }
  }
  return buf.toString();
}

bool luhnCheck(String digits) {
  if (digits.isEmpty || !RegExp(r'^\d+$').hasMatch(digits)) return false;
  var sum = 0;
  var alternate = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var n = int.parse(digits[i]);
    if (alternate) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

String? validateCardNumberDigits(String digits, {bool requireLuhn = true}) {
  if (digits.length < 13) {
    return 'Informe o número completo do cartão';
  }
  final brand = detectCreditCardBrand(digits);
  final spec = specForBrand(brand);

  if (brand != CreditCardBrand.unknown && digits.length != spec.maxDigits) {
    return 'Informe os ${spec.maxDigits} dígitos do cartão (${spec.displayName})';
  }
  if (brand == CreditCardBrand.unknown && (digits.length < 13 || digits.length > 19)) {
    return 'Número do cartão inválido';
  }
  if (requireLuhn && !luhnCheck(digits)) {
    return 'Número do cartão inválido';
  }
  return null;
}
