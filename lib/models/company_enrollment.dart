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
