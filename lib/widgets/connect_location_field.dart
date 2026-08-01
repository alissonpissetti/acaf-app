import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Campo de localização (pill) — toque para trocar região; refresh volta ao GPS.
class ConnectLocationField extends StatelessWidget {
  const ConnectLocationField({
    super.key,
    required this.label,
    required this.loading,
    this.onTap,
    this.onUseCurrentLocation,
    this.showCurrentLocationAction = true,
  });

  final String label;
  final bool loading;
  final VoidCallback? onTap;
  final VoidCallback? onUseCurrentLocation;
  final bool showCurrentLocationAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                if (loading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
                  )
                else
                  const Icon(Icons.location_on_outlined, size: 22, color: AppColors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showCurrentLocationAction && onUseCurrentLocation != null && !loading)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    tooltip: 'Usar localização atual',
                    onPressed: onUseCurrentLocation,
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textMuted),
                  )
                else if (!loading)
                  const Icon(Icons.expand_more_rounded, size: 22, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
