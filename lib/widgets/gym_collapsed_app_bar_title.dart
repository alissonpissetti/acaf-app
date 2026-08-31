import 'package:flutter/material.dart';

import 'brand_logo.dart';
import '../theme/app_typography.dart';

/// Título da AppBar fixa ao rolar (logo Connect + nome da academia).
class GymCollapsedAppBarTitle extends StatelessWidget {
  const GymCollapsedAppBarTitle({
    super.key,
    required this.label,
    this.logoHeight = 28,
  });

  final String label;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandLogo(height: logoHeight),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle.copyWith(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
