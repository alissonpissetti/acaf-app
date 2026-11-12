/// Marca movly. — PNG extraídos do manual `movly-by-acaf.app.pdf` (p. 3).
abstract final class BrandAssets {
  /// Wordmark **movly.** em `#8254E4` — vetor isolado (sem lockup); preferir PNG em [BrandLogo].
  static const movlyLogoPurpleSvg = 'assets/branding/movly-logo-purple.svg';
  static const movlyLogoPurpleOnLime = 'assets/branding/movly-logo-purple-on-lime.png';
  static const movlyLogoLimeOnPurple = 'assets/branding/movly-logo-lime-on-purple.png';
  static const movlyLogoLimeOnGradient = 'assets/branding/movly-logo-lime-on-gradient.png';

  @Deprecated('Use variant-specific PNG')
  static const movlyLogoPurple = 'assets/branding/movly-logo-purple-on-lime.png';
  @Deprecated('Use variant-specific PNG')
  static const movlyLogoLime = 'assets/branding/movly-logo-lime-on-purple.png';
  @Deprecated('Use variant-specific PNG')
  static const movlyLogoWhite = 'assets/branding/movly-logo-lime-on-purple.png';
  static const movlyMark = 'assets/branding/movly-mark.svg';
  static const movlyMarkLime = 'assets/branding/movly-mark-lime.svg';
}
