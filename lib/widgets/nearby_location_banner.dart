import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class NearbyLocationBanner extends StatelessWidget {
  const NearbyLocationBanner({
    super.key,
    required this.loading,
    required this.areaLabel,
    required this.onRefresh,
  });

  final bool loading;
  final String areaLabel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(6),
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
                  )
                : const Icon(Icons.my_location_rounded, size: 18, color: AppColors.orange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Perto de mim', style: AppTypography.caption.copyWith(color: AppColors.orange)),
                Text(
                  loading ? 'Obtendo localização...' : areaLabel,
                  style: AppTypography.bodyMuted,
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: loading ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.orange, size: 20),
          ),
        ],
      ),
    );
  }
}
