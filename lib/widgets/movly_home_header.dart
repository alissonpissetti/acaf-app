import 'package:flutter/material.dart';

import '../branding/movly_brand.dart';
import '../screens/user_account_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'brand_logo.dart';

/// Topo da home — **chartreuse** como no manual movly.app (cliente final).
class MovlyHomeHeader extends StatelessWidget {
  const MovlyHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.lime,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pageX, 10, AppSpacing.pageX, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: BrandLogo.totalHeight(42),
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    const BrandLogo(
                      height: 42,
                      variant: BrandLogoVariant.lockupOnLime,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _HeaderIconButton(
                          icon: Icons.person_outline_rounded,
                          tooltip: 'Minha conta',
                          onTap: () => UserAccountScreen.open(context),
                        ),
                        const SizedBox(width: 8),
                        _HeaderIconButton(
                          icon: Icons.notifications_none_rounded,
                          tooltip: 'Notificações',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                MovlyBrand.movementLine,
                style: AppTypography.tagline.copyWith(
                  fontSize: 18,
                  color: AppColors.onLime,
                  height: 1.2,
                ),
              ),
              Text(
                MovlyBrand.wellbeingLine,
                style: AppTypography.tagline.copyWith(
                  fontSize: 18,
                  color: AppColors.onLime,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                MovlyBrand.tagline,
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onLime.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.onLime.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: AppColors.onLime, size: 22),
          ),
        ),
      ),
    );
  }
}
