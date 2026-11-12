import 'package:flutter/material.dart';

import 'brand_logo.dart';
import '../theme/app_typography.dart';

/// Título da AppBar fixa ao rolar (logo Movly + nome da academia/rede).
class GymCollapsedAppBarTitle extends StatelessWidget {
  const GymCollapsedAppBarTitle({
    super.key,
    required this.label,
    this.logoHeight = 28,
    this.onHero = false,
  });

  final String label;
  final double logoHeight;

  /// Toolbar na faixa roxa (hero ou barra colapsada) — logo lima sobre roxo.
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final logo = BrandLogo(
      height: logoHeight,
      variant: onHero ? BrandLogoVariant.lime : BrandLogoVariant.purple,
    );

    final labelStyle = onHero
        ? AppTypography.cardTitle.copyWith(fontSize: 16, color: Colors.white)
        : AppTypography.cardTitle.copyWith(fontSize: 16);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
      ],
    );
  }
}
