import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ConnectLocationChip extends StatelessWidget {
  const ConnectLocationChip({
    super.key,
    required this.label,
    required this.loading,
    this.onRefresh,
  });

  final String label;
  final bool loading;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
            )
          else
            const Icon(Icons.location_on_outlined, size: 18, color: AppColors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRefresh != null && !loading)
            InkWell(
              onTap: onRefresh,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.refresh_rounded, size: 18, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
