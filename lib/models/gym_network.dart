/// Rede de academias associada (marca com uma ou mais unidades).
class GymNetwork {
  const GymNetwork({
    required this.id,
    required this.name,
    this.tagline,
    this.brandLogoAsset,
    this.brandLogoUrl,
    this.brandLogoWidthFactor = 1,
  });

  final String id;
  final String name;
  final String? tagline;
  final String? brandLogoAsset;
  final String? brandLogoUrl;
  final double brandLogoWidthFactor;

  String? get logoSource => brandLogoUrl ?? brandLogoAsset;
}
