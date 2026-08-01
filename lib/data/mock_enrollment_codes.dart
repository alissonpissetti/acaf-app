class CompanyEnrollment {
  const CompanyEnrollment({
    required this.companyName,
    required this.code,
    this.collaboratorLabel,
  });

  final String companyName;
  final String code;
  final String? collaboratorLabel;
}

class EnrollmentInvite {
  const EnrollmentInvite({
    required this.code,
    required this.companyName,
    required this.hint,
  });

  final String code;
  final String companyName;
  final String hint;
}

/// Códigos de adesão liberados pelas empresas (mock — substituir por API).
const List<EnrollmentInvite> mockEnrollmentInvites = [
  EnrollmentInvite(
    code: 'ACAF-2026',
    companyName: 'Grupo Horizonte',
    hint: 'Enviado pelo RH no e-mail de boas-vindas.',
  ),
  EnrollmentInvite(
    code: 'RH-CURITIBA',
    companyName: 'Tech Solutions PR',
    hint: 'Disponível no portal do colaborador.',
  ),
  EnrollmentInvite(
    code: 'WELLNESS-01',
    companyName: 'Indústrias Alfa',
    hint: 'Solicite ao gestor direto.',
  ),
];

EnrollmentInvite? findEnrollmentInvite(String rawCode) {
  final normalized = rawCode.trim().toUpperCase().replaceAll(' ', '');
  for (final invite in mockEnrollmentInvites) {
    final inviteCode = invite.code.toUpperCase().replaceAll(' ', '');
    if (inviteCode == normalized) return invite;
  }
  return null;
}
