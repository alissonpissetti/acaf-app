import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Tela placeholder para fluxos do mockup (dados, financeiro, etc.).
class ConnectPlaceholderScreen extends StatelessWidget {
  const ConnectPlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.construction_outlined,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageX),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Icon(icon, size: 48, color: AppColors.orange),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.pageTitle.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            Text(description, style: AppTypography.bodyMuted),
          ],
        ),
      ),
    );
  }
}
