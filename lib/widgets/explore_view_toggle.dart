import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum ExploreViewMode { list, map }

/// Alternância lista / mapa na tela Explorar.
class ExploreViewToggle extends StatelessWidget {
  const ExploreViewToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final ExploreViewMode mode;
  final ValueChanged<ExploreViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ExploreViewMode>(
      segments: const [
        ButtonSegment(
          value: ExploreViewMode.list,
          icon: Icon(Icons.format_list_bulleted_rounded, size: 18),
          tooltip: 'Lista',
        ),
        ButtonSegment(
          value: ExploreViewMode.map,
          icon: Icon(Icons.map_rounded, size: 18),
          tooltip: 'Mapa',
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textMuted;
        }),
        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 11)),
      ),
      showSelectedIcon: false,
    );
  }
}
