import 'package:flutter/material.dart';

import '../branding/movly_brand.dart';
import '../screens/user_account_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'brand_logo.dart';
import 'connect_location_chip.dart';

class ConnectPageHeader extends StatelessWidget {
  const ConnectPageHeader({
    super.key,
    this.title,
    this.subtitle,
    this.locationLabel,
    this.trailing,
    this.onRefreshLocation,
    this.locationLoading = false,
    this.showBrandBand = true,
  });

  final String? title;
  final String? subtitle;
  final String? locationLabel;
  final Widget? trailing;
  final VoidCallback? onRefreshLocation;
  final bool locationLoading;
  final bool showBrandBand;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBrandBand) const _MovlyBrandBand(),
        ColoredBox(
          color: AppColors.surface,
          child: SafeArea(
            bottom: false,
            top: !showBrandBand,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageX,
                showBrandBand ? 16 : 8,
                AppSpacing.pageX,
                title == null && subtitle == null && locationLabel == null ? 12 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!showBrandBand)
                    SizedBox(
                      height: BrandLogo.totalHeight(40),
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 96),
                            child: BrandLogo(height: 40),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: trailing ?? const _HeaderActions(),
                          ),
                        ],
                      ),
                    ),
                  if (title != null) ...[
                    if (!showBrandBand) const SizedBox(height: 24),
                    Text(title!, style: AppTypography.pageTitle.copyWith(fontSize: 22)),
                  ],
                  if (subtitle != null) ...[
                    SizedBox(height: title != null ? 8 : 16),
                    Text(subtitle!, style: AppTypography.pageSubtitle),
                  ],
                  if (locationLabel != null) ...[
                    const SizedBox(height: 16),
                    ConnectLocationChip(
                      label: locationLabel!,
                      loading: locationLoading,
                      onRefresh: onRefreshLocation,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MovlyBrandBand extends StatelessWidget {
  const _MovlyBrandBand();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pageX, 12, AppSpacing.pageX, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: BrandLogo.totalHeight(38),
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 96),
                      child: BrandLogo(height: 38, variant: BrandLogoVariant.gradient),
                    ),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: _HeaderActions(onGradient: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                MovlyBrand.movementLine,
                style: AppTypography.tagline.copyWith(
                  fontSize: 16,
                  color: AppColors.movlyPurpleDeep,
                ),
              ),
              Text(
                MovlyBrand.wellbeingLine,
                style: AppTypography.tagline.copyWith(
                  fontSize: 16,
                  color: AppColors.movlyLime,
                  shadows: const [
                    Shadow(
                      color: Color(0x66000000),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                MovlyBrand.tagline,
                style: AppTypography.bodyMuted.copyWith(
                  color: AppColors.movlyPurpleDeep.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({this.onGradient = false});

  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    final bg = onGradient ? Colors.white.withValues(alpha: 0.72) : AppColors.surfaceMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderIconButton(
          icon: Icons.person_outline_rounded,
          tooltip: 'Minha conta',
          backgroundColor: bg,
          onTap: () => UserAccountScreen.open(context),
        ),
        const SizedBox(width: 8),
        _NotificationButton(backgroundColor: bg),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.backgroundColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: AppColors.foreground, size: 22),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.backgroundColor});

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {},
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.notifications_none_rounded, color: AppColors.foreground, size: 22),
        ),
      ),
    );
  }
}
