import 'package:flutter/material.dart';

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
  });

  final String? title;
  final String? subtitle;
  final String? locationLabel;
  final Widget? trailing;
  final VoidCallback? onRefreshLocation;
  final bool locationLoading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageX,
            8,
            AppSpacing.pageX,
            title == null && subtitle == null && locationLabel == null ? 12 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 44,
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
                const SizedBox(height: 24),
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
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderIconButton(
          icon: Icons.person_outline_rounded,
          tooltip: 'Minha conta',
          onTap: () => UserAccountScreen.open(context),
        ),
        const SizedBox(width: 8),
        const _NotificationButton(),
      ],
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
      color: AppColors.surfaceMuted,
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
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
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
