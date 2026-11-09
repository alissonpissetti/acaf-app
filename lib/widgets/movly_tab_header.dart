import 'package:flutter/material.dart';

import '../screens/user_account_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Cabeçalho simples para abas internas (ex.: Minha conta).
class MovlyTabHeader extends StatelessWidget {
  const MovlyTabHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pageX, 8, AppSpacing.pageX, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTypography.pageTitle.copyWith(fontSize: 24)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(subtitle!, style: AppTypography.pageSubtitle),
                        ],
                      ],
                    ),
                  ),
                  trailing ??
                      IconButton(
                        onPressed: () => UserAccountScreen.open(context),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceMuted,
                        ),
                        icon: const Icon(Icons.person_outline_rounded),
                        tooltip: 'Perfil',
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
